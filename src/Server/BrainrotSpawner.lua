-- BrainrotSpawner.lua (ServerScriptService)
-- Spawnt Brainrots auf dem Runway, bewegt sie von A nach B und verwaltet das 3-Minuten-Fangfenster.
-- Erwartet: In Workspace "RunwayStart" und "RunwayEnd" als Parts.

local Players         = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config          = require(game.ReplicatedStorage.Shared.Config)
local DataStore       = require(script.Parent.DataStore)
local ZoneManager     = require(script.Parent.ZoneManager)

local BrainrotSpawner = {}

-- Alle aktiven Brainrot-Instanzen: { model, config, mutation, despawnTime, caught }
local activebrainrots = {}

-- Remote Events (werden in ReplicatedStorage erwartet)
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local catchBrainrotRemote  = remotes:WaitForChild("CatchBrainrot")
local brainrotSpawnedRemote = remotes:WaitForChild("BrainrotSpawned")
local brainrotDespawnRemote = remotes:WaitForChild("BrainrotDespawned")

-- Zufaelligen Brainrot-Typ per Gewichtung waehlen
local function rollBrainrot()
	local roll  = math.random()
	local total = 0
	for _, b in ipairs(Config.Brainrots) do
		total += b.chance
		if roll <= total then
			return b
		end
	end
	return Config.Brainrots[1] -- Fallback
end

-- Zufaellige Mutation eines Brainrots behalten (festgelegt beim Spawn)
local function rollMutation(brainrotCfg)
	return brainrotCfg.mutation -- aktuell 1 Mutation pro Typ; koennte spaeter per RNG erweitert werden
end

-- Brainrot-Modell im Workspace erstellen
local function createModel(brainrotCfg, startPos)
	-- Platzhalter-Part bis echte Modelle vorhanden sind
	local model = Instance.new("Model")
	model.Name  = brainrotCfg.name

	local part  = Instance.new("Part")
	part.Name   = "HumanoidRootPart"
	part.Size   = Vector3.new(3, 4, 3)
	part.Anchored = false
	part.Position = startPos + Vector3.new(0, 2, 0)

	-- Farbe nach Seltenheit
	local rarityCfg = Config.Rarities[brainrotCfg.rarity]
	if rarityCfg then
		part.Color = rarityCfg.color
	end

	part.Parent  = model
	model.PrimaryPart = part

	-- Floating Label (BillboardGui)
	local billboard = Instance.new("BillboardGui")
	billboard.Size  = UDim2.new(0, 200, 0, 50)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = false
	billboard.Parent = part

	local label = Instance.new("TextLabel")
	label.Size  = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.TextColor3 = rarityCfg and rarityCfg.color or Color3.new(1,1,1)
	label.TextStrokeTransparency = 0
	label.Font  = Enum.Font.GothamBold
	label.TextScaled = true
	label.Text  = brainrotCfg.name .. "\n" .. brainrotCfg.rarity .. " · $" .. brainrotCfg.sell
	label.Parent = billboard

	model.Parent = workspace
	return model
end

-- Einen Brainrot spawnen
local function spawnBrainrot()
	local startPart = workspace:FindFirstChild("RunwayStart")
	local endPart   = workspace:FindFirstChild("RunwayEnd")
	if not startPart or not endPart then
		warn("[BrainrotSpawner] RunwayStart oder RunwayEnd fehlt in Workspace!")
		return
	end

	local cfg      = rollBrainrot()
	local mutation = rollMutation(cfg)
	local startPos = startPart.Position
	local endPos   = endPart.Position
	local model    = createModel(cfg, startPos)

	local spawnTime  = tick()
	local despawnTime = spawnTime + Config.Incubator.runwayWindowSecs -- 3-Minuten-Fenster

	local entry = {
		model       = model,
		config      = cfg,
		mutation    = mutation,
		startPos    = startPos,
		endPos      = endPos,
		spawnTime   = spawnTime,
		despawnTime = despawnTime,
		caught      = false,
		id          = tostring(spawnTime) .. cfg.name,
	}
	table.insert(activebrainrots, entry)

	-- Alle Spieler ueber neuen Brainrot informieren
	brainrotSpawnedRemote:FireAllClients({
		id       = entry.id,
		name     = cfg.name,
		rarity   = cfg.rarity,
		mutation = mutation,
		sell     = cfg.sell,
		dph      = cfg.dph,
		timeLeft = Config.Incubator.runwayWindowSecs,
	})

	-- Bewegung: Brainrot laeuft von A nach B
	task.spawn(function()
		local duration = Config.Incubator.runwayWindowSecs
		local elapsed  = 0
		local stepTime = 0.1

		while elapsed < duration and not entry.caught do
			task.wait(stepTime)
			elapsed += stepTime

			if not model or not model.Parent then break end

			local alpha = elapsed / duration
			local newPos = startPos:Lerp(endPos, alpha)
			model:SetPrimaryPartCFrame(CFrame.new(newPos + Vector3.new(0, 2, 0)))
		end

		-- Nach Ablauf: despawnen falls nicht gefangen
		if not entry.caught and model and model.Parent then
			model:Destroy()
			brainrotDespawnRemote:FireAllClients(entry.id)
			-- Aus aktiver Liste entfernen
			for i, e in ipairs(activebrainrots) do
				if e.id == entry.id then
					table.remove(activebrainrots, i)
					break
				end
			end
		end
	end)
end

-- Fang-Request vom Client verarbeiten
catchBrainrotRemote.OnServerEvent:Connect(function(player, brainrotId)
	-- Brainrot in aktiver Liste suchen
	local entry = nil
	local idx   = nil
	for i, e in ipairs(activebrainrots) do
		if e.id == brainrotId then
			entry = e
			idx   = i
			break
		end
	end

	if not entry then
		catchBrainrotRemote:FireClient(player, false, "Brainrot nicht gefunden")
		return
	end

	if entry.caught then
		catchBrainrotRemote:FireClient(player, false, "Bereits gefangen")
		return
	end

	if tick() > entry.despawnTime then
		catchBrainrotRemote:FireClient(player, false, "Zeit abgelaufen")
		return
	end

	-- Nur auf dem Runway fangen erlaubt
	local zone = ZoneManager.getZone(player)
	if zone ~= "Runway" then
		catchBrainrotRemote:FireClient(player, false, "Du musst auf dem Runway stehen")
		return
	end

	-- Zur Base hinzufuegen
	local brainrotData = {
		name     = entry.config.name,
		rarity   = entry.config.rarity,
		mutation = entry.mutation,
		traits   = {},
	}
	local ok, err = DataStore.addBrainrot(player, brainrotData)
	if not ok then
		catchBrainrotRemote:FireClient(player, false, err or "Base voll")
		return
	end

	-- Gefangen: markieren und Modell entfernen
	entry.caught = true
	if entry.model and entry.model.Parent then
		entry.model:Destroy()
	end
	table.remove(activebrainrots, idx)

	brainrotDespawnRemote:FireAllClients(entry.id)
	catchBrainrotRemote:FireClient(player, true, brainrotData)
end)

-- Alle aktiven Brainrots zurueckgeben (fuer andere Systeme, z.B. Trait-Farming)
function BrainrotSpawner.getActive()
	return activebrainrots
end

-- Spawn-Schleife starten
task.spawn(function()
	while true do
		task.wait(Config.BrainrotSpawnInterval)
		spawnBrainrot()
	end
end)

return BrainrotSpawner
