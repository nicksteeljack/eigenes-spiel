-- DataStore.lua (ServerScriptService)
-- Speichert und laedt alle Spielerdaten. Einzige Stelle im Spiel die DataStore beruehrt.

local DataStoreService = game:GetService("DataStoreService")
local Players          = game:GetService("Players")
local Config           = require(game.ReplicatedStorage.Shared.Config)

local DataStore = {}
local store     = DataStoreService:GetDataStore("PlayerData_v1")
local cache     = {} -- [userId] = data

-- Standardwerte fuer einen neuen Spieler
local function defaultData()
	return {
		cash          = 0,
		eventCoins    = 0,
		rebirthLevel  = 0,
		rebirthPoints = 0,
		baseSlots     = Config.Base.startSlots,
		baseSkin      = "Default",
		brainrots     = {},   -- { brainrotName, mutation, traits[] }
		inventory     = {     -- Werkzeuge und Items
			Pilzmesser = false,
			Korb       = false,
			Angelrute  = false,
			Schaufel   = 0,   -- Haltbarkeit (Anzahl verbleibende Verwendungen)
		},
		materials     = {},   -- { ["Steinpilz"] = anzahl, ... }
		waffen        = {},   -- { waffenName, ... }
		gamepasses    = {
			Pilze    = false,
			Muscheln = false,
			Angel    = false,
		},
		lockedTraits  = {},   -- freigeschaltete gesperrte Traits
		stats         = {
			totalEarned   = 0,
			brainrotsCaught = 0,
			rebirths      = 0,
		},
	}
end

-- Laedt Daten aus dem DataStore (mit Retry bei Fehler)
local function loadFromStore(userId)
	local attempts = 0
	local data
	repeat
		attempts += 1
		local ok, result = pcall(function()
			return store:GetAsync(tostring(userId))
		end)
		if ok then
			data = result
			break
		else
			warn("[DataStore] Ladefehler fuer " .. userId .. ": " .. tostring(result))
			task.wait(2)
		end
	until attempts >= 3
	return data
end

-- Speichert Daten in den DataStore (mit Retry bei Fehler)
local function saveToStore(userId, data)
	local attempts = 0
	repeat
		attempts += 1
		local ok, err = pcall(function()
			store:SetAsync(tostring(userId), data)
		end)
		if ok then
			return true
		else
			warn("[DataStore] Speicherfehler fuer " .. userId .. ": " .. tostring(err))
			task.wait(2)
		end
	until attempts >= 3
	return false
end

-- Spieler tritt bei: Daten laden und in Cache schreiben
function DataStore.onPlayerAdded(player)
	local userId = player.UserId
	local stored = loadFromStore(userId)
	local data   = defaultData()

	if stored then
		-- Fehlende Felder aus defaultData ergaenzen (Update-Sicherheit)
		for key, value in pairs(data) do
			if stored[key] == nil then
				stored[key] = value
			end
		end
		cache[userId] = stored
	else
		cache[userId] = data
	end

	return cache[userId]
end

-- Spieler verlaesst: Daten speichern und Cache leeren
function DataStore.onPlayerRemoving(player)
	local userId = player.UserId
	if cache[userId] then
		saveToStore(userId, cache[userId])
		cache[userId] = nil
	end
end

-- Daten eines Spielers aus Cache holen
function DataStore.get(player)
	return cache[player.UserId]
end

-- Einen einzelnen Wert speichern
function DataStore.set(player, key, value)
	if cache[player.UserId] then
		cache[player.UserId][key] = value
	end
end

-- Geld hinzufuegen (positiv oder negativ)
function DataStore.addCash(player, amount)
	local data = cache[player.UserId]
	if not data then return end
	data.cash = math.max(0, data.cash + amount)
	data.stats.totalEarned += math.max(0, amount)
end

-- Event Coins hinzufuegen
function DataStore.addCoins(player, amount)
	local data = cache[player.UserId]
	if not data then return end
	data.eventCoins = math.max(0, data.eventCoins + amount)
end

-- Brainrot zur Base hinzufuegen
function DataStore.addBrainrot(player, brainrotData)
	local data = cache[player.UserId]
	if not data then return false end
	if #data.brainrots >= data.baseSlots then
		return false, "Base ist voll"
	end
	table.insert(data.brainrots, brainrotData)
	data.stats.brainrotsCaught += 1
	return true
end

-- Brainrot aus Base entfernen (nach Index)
function DataStore.removeBrainrot(player, index)
	local data = cache[player.UserId]
	if not data then return end
	table.remove(data.brainrots, index)
end

-- Material hinzufuegen (Pilze, Fische, Muscheln)
function DataStore.addMaterial(player, materialName, amount)
	local data = cache[player.UserId]
	if not data then return end
	data.materials[materialName] = (data.materials[materialName] or 0) + amount
end

-- Material entfernen (z.B. beim Rebirth oder Verkauf)
function DataStore.removeMaterial(player, materialName, amount)
	local data = cache[player.UserId]
	if not data then return false end
	local current = data.materials[materialName] or 0
	if current < amount then return false end
	data.materials[materialName] = current - amount
	return true
end

-- Passives Einkommen aller Brainrots berechnen ($/h)
function DataStore.getTotalDPH(player)
	local data = cache[player.UserId]
	if not data then return 0 end

	local brainrotMap = {}
	for _, b in ipairs(Config.Brainrots) do
		brainrotMap[b.name] = b
	end

	local total = 0
	for _, entry in ipairs(data.brainrots) do
		local cfg = brainrotMap[entry.name]
		if cfg then
			total += cfg.dph
		end
	end

	local rebirthData = Config.Rebirth.levels[data.rebirthLevel]
	local multiplier  = rebirthData and rebirthData.multiplier or 1

	return total * multiplier
end

-- Manuelles Speichern (z.B. alle 5 Minuten)
function DataStore.saveAll()
	for userId, data in pairs(cache) do
		saveToStore(userId, data)
	end
end

-- Auto-Save alle 5 Minuten
task.spawn(function()
	while true do
		task.wait(300)
		DataStore.saveAll()
	end
end)

-- Beim Server-Shutdown alles speichern
game:BindToClose(function()
	DataStore.saveAll()
end)

-- Events verdrahten
Players.PlayerAdded:Connect(DataStore.onPlayerAdded)
Players.PlayerRemoving:Connect(DataStore.onPlayerRemoving)

return DataStore
