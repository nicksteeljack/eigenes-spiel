-- TraitManager.lua (ServerScriptService)
-- Verwaltet Trait-Farming auf dem Runway und im Incubator.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config            = require(game.ReplicatedStorage.Shared.Config)
local DataStore         = require(script.Parent.DataStore)
local BrainrotSpawner   = require(script.Parent.BrainrotSpawner)

local remotes           = ReplicatedStorage:WaitForChild("Remotes")
local traitRemote       = remotes:WaitForChild("ApplyTrait")    -- { brainrotId, traitName, method = "Runway"|"Incubator" }
local incubatorRemote   = remotes:WaitForChild("IncubatorStatus")

-- Aktive Incubator-Jobs: [userId] = { brainrotIndex, traitName, finishTime }
local incubatorJobs = {}

-- Trait-Config nach Name suchen
local function findTrait(name)
	for _, t in ipairs(Config.Traits) do
		if t.name == name then return t end
	end
end

-- Prueft ob ein Event-Trait gerade verfuegbar ist (Snap aktiv?)
-- SnapManager wird spaeter gesetzt; hier als globale Referenz
local SnapManager = nil
function TraitManager.setSnapManager(sm)
	SnapManager = sm
end

local function isTraitAvailable(traitCfg, player)
	if traitCfg.type == "Standard" then
		return true
	end
	if traitCfg.type == "Locked" then
		local data = DataStore.get(player)
		if not data then return false end
		for _, t in ipairs(data.lockedTraits) do
			if t == traitCfg.name then return true end
		end
		return false
	end
	if traitCfg.type == "Event" then
		if not SnapManager then return false end
		return SnapManager.isSnapActive(traitCfg.snapName)
	end
	return false
end

-- Trait anwenden (Runway oder Incubator)
traitRemote.OnServerEvent:Connect(function(player, request)
	if not request then return end

	local data = DataStore.get(player)
	if not data then return end

	local traitName     = request.traitName
	local brainrotIndex = request.brainrotIndex
	local method        = request.method -- "Runway" oder "Incubator"

	local traitCfg = findTrait(traitName)
	if not traitCfg then
		traitRemote:FireClient(player, { success = false, msg = "Unbekannter Trait" })
		return
	end

	if not isTraitAvailable(traitCfg, player) then
		traitRemote:FireClient(player, { success = false, msg = "Trait nicht verfuegbar" })
		return
	end

	local brainrot = data.brainrots[brainrotIndex]
	if not brainrot then
		traitRemote:FireClient(player, { success = false, msg = "Brainrot nicht gefunden" })
		return
	end

	-- Kosten berechnen: 20% des Verkaufswerts * Trait-Multiplikator
	local brainrotCfg = nil
	for _, b in ipairs(Config.Brainrots) do
		if b.name == brainrot.name then brainrotCfg = b; break end
	end
	if not brainrotCfg then
		traitRemote:FireClient(player, { success = false, msg = "Brainrot-Config fehlt" })
		return
	end

	local cost = math.floor(brainrotCfg.sell * Config.Incubator.traitCostPct * traitCfg.costMultiplier)
	if data.cash < cost then
		traitRemote:FireClient(player, { success = false, msg = "Nicht genug $ (" .. cost .. " benoetigt)" })
		return
	end

	-- Geld abziehen (auch bei Fehlschlag verloren)
	DataStore.addCash(player, -cost)

	if method == "Runway" then
		-- Sofortiger Versuch mit Erfolgs-Chance
		local roll = math.random()
		if roll <= traitCfg.chance then
			table.insert(brainrot.traits, traitName)
			traitRemote:FireClient(player, { success = true, traitName = traitName, brainrotIndex = brainrotIndex })
		else
			traitRemote:FireClient(player, { success = false, msg = "Fehlschlag! Geld verloren." })
		end

	elseif method == "Incubator" then
		-- Pruefe ob Incubator frei
		local uid = player.UserId
		if incubatorJobs[uid] then
			DataStore.addCash(player, cost) -- Geld zurueckgeben
			traitRemote:FireClient(player, { success = false, msg = "Incubator bereits in Betrieb" })
			return
		end

		local finishTime = tick() + Config.Incubator.durationSecs
		incubatorJobs[uid] = {
			brainrotIndex = brainrotIndex,
			traitName     = traitName,
			traitCfg      = traitCfg,
			finishTime    = finishTime,
			player        = player,
		}

		traitRemote:FireClient(player, {
			success    = true,
			incubating = true,
			finishTime = finishTime,
			traitName  = traitName,
		})

		-- Warten und dann Ergebnis auswerten
		task.delay(Config.Incubator.durationSecs, function()
			if not incubatorJobs[uid] then return end -- Job wurde abgebrochen
			local job = incubatorJobs[uid]
			incubatorJobs[uid] = nil

			local currentData = DataStore.get(player)
			if not currentData then return end

			local targetBrainrot = currentData.brainrots[job.brainrotIndex]
			if not targetBrainrot then return end

			local roll = math.random()
			if roll <= job.traitCfg.chance then
				table.insert(targetBrainrot.traits, job.traitName)
				incubatorRemote:FireClient(player, { success = true, traitName = job.traitName, brainrotIndex = job.brainrotIndex })
			else
				incubatorRemote:FireClient(player, { success = false, msg = "Incubator-Fehlschlag! Zeit und Geld verloren." })
			end
		end)
	end
end)

-- Status-Abfrage: Wie lange laeuft der Incubator noch?
incubatorRemote.OnServerEvent:Connect(function(player)
	local uid = player.UserId
	local job = incubatorJobs[uid]
	if job then
		incubatorRemote:FireClient(player, {
			active     = true,
			timeLeft   = math.max(0, job.finishTime - tick()),
			traitName  = job.traitName,
		})
	else
		incubatorRemote:FireClient(player, { active = false })
	end
end)

local TraitManager = {}
return TraitManager
