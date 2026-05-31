-- CollectManager.lua (ServerScriptService)
-- Verwaltet alle Sammel-Aktivitaeten: Pilze (Wald), Fischen (Wasser), Muscheln (Strand).

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config            = require(game.ReplicatedStorage.Shared.Config)
local DataStore         = require(script.Parent.DataStore)
local ZoneManager       = require(script.Parent.ZoneManager)

local remotes           = ReplicatedStorage:WaitForChild("Remotes")
local collectRemote     = remotes:WaitForChild("Collect")      -- Client -> Server: { type = "Pilz"|"Fisch"|"Muschel" }
local sellMaterialRemote = remotes:WaitForChild("SellMaterial") -- Client -> Server: { materialName, amount }
local inventoryRemote   = remotes:WaitForChild("UpdateInventory")

-- Cooldowns pro Spieler pro Aktivitaet (verhindert Spam)
local cooldowns = {} -- [userId][type] = lastUsedTick

local function getCooldown(player, actType)
	local uid = player.UserId
	cooldowns[uid] = cooldowns[uid] or {}
	return cooldowns[uid][actType] or 0
end

local function setCooldown(player, actType)
	local uid = player.UserId
	cooldowns[uid] = cooldowns[uid] or {}
	cooldowns[uid][actType] = tick()
end

-- Cooldown-Dauer (Sekunden) — Gamepasses verkuerzen dies
local BASE_COOLDOWN = {
	Pilz   = 3,
	Fisch  = 5,
	Muschel = 4,
}

local function getCooldownDuration(player, actType)
	local data = DataStore.get(player)
	local base = BASE_COOLDOWN[actType] or 3
	if not data then return base end

	local passMap = {
		Pilz    = "Pilze",
		Fisch   = "Angel",
		Muschel = "Muscheln",
	}
	local passKey = passMap[actType]
	if passKey and data.gamepasses[passKey] then
		local mult = Config.Gamepasses[passKey].speedMultiplier
		return base / mult
	end
	return base
end

-- Zufaelligen Eintrag aus einer Tabelle waehlen
local function randomFrom(tbl)
	return tbl[math.random(1, #tbl)]
end

-- Pilze sammeln
local function collectPilz(player)
	local data = DataStore.get(player)
	if not data then return false, "Nicht eingeloggt" end

	-- Werkzeug-Pruefung
	if not data.inventory.Pilzmesser then
		return false, "Du brauchst ein Pilzmesser"
	end
	if not data.inventory.Korb then
		return false, "Du brauchst einen Korb"
	end

	-- Korb-Kapazitaet pruefen
	local korbMax = Config.Werkzeuge.Korb.maxCapacity
	local total   = 0
	for name, _ in pairs(Config.Pilze) do
		total += (data.materials[Config.Pilze[name] and Config.Pilze[name].name] or 0)
	end
	-- Einfacher Count aller Pilze im Inventar
	local pilzCount = 0
	for _, pilz in ipairs(Config.Pilze) do
		pilzCount += (data.materials[pilz.name] or 0)
	end
	if pilzCount >= korbMax then
		return false, "Korb ist voll (max. " .. korbMax .. ")"
	end

	-- Zonen-Pruefung
	if ZoneManager.getZone(player) ~= "Wald" then
		return false, "Du musst im Wald sein"
	end

	local pilz = randomFrom(Config.Pilze)
	DataStore.addMaterial(player, pilz.name, 1)
	return true, pilz
end

-- Fischen
local function collectFisch(player)
	local data = DataStore.get(player)
	if not data then return false, "Nicht eingeloggt" end

	if not data.inventory.Angelrute then
		return false, "Du brauchst eine Angelrute"
	end
	local koeder = data.materials["Koeder"] or 0
	if koeder <= 0 then
		return false, "Du hast keinen Koeder"
	end

	if ZoneManager.getZone(player) ~= "Wasser" then
		return false, "Du musst am Wasser sein"
	end

	-- Koeder verbrauchen
	DataStore.removeMaterial(player, "Koeder", 1)

	local fisch = randomFrom(Config.Fische)
	DataStore.addMaterial(player, fisch.name, 1)
	return true, fisch
end

-- Muscheln graben
local function collectMuschel(player)
	local data = DataStore.get(player)
	if not data then return false, "Nicht eingeloggt" end

	if not data.inventory.Schaufel or data.inventory.Schaufel <= 0 then
		return false, "Du brauchst eine Schaufel"
	end

	if ZoneManager.getZone(player) ~= "Strand" then
		return false, "Du musst am Strand sein"
	end

	-- Schaufel-Haltbarkeit verringern
	data.inventory.Schaufel -= 1
	if data.inventory.Schaufel <= 0 then
		data.inventory.Schaufel = 0
	end

	local muschel = randomFrom(Config.Muscheln)
	DataStore.addMaterial(player, muschel.name, 1)
	return true, muschel, data.inventory.Schaufel
end

-- Collect-Request vom Client
collectRemote.OnServerEvent:Connect(function(player, request)
	local actType = request and request.type
	if not actType then return end

	-- Cooldown pruefen
	local cooldownDur = getCooldownDuration(player, actType)
	if tick() - getCooldown(player, actType) < cooldownDur then
		collectRemote:FireClient(player, { success = false, msg = "Warte kurz..." })
		return
	end
	setCooldown(player, actType)

	local ok, result, extra
	if actType == "Pilz" then
		ok, result, extra = collectPilz(player)
	elseif actType == "Fisch" then
		ok, result, extra = collectFisch(player)
	elseif actType == "Muschel" then
		ok, result, extra = collectMuschel(player)
	else
		collectRemote:FireClient(player, { success = false, msg = "Unbekannter Typ" })
		return
	end

	if ok then
		local data = DataStore.get(player)
		collectRemote:FireClient(player, {
			success    = true,
			type       = actType,
			item       = result,
			schaufelHP = extra, -- nur bei Muscheln
			materials  = data and data.materials or {},
		})
	else
		collectRemote:FireClient(player, { success = false, msg = result })
	end
end)

-- Material verkaufen
sellMaterialRemote.OnServerEvent:Connect(function(player, materialName, amount)
	if not materialName or not amount or amount <= 0 then return end

	-- Materialwert suchen
	local sellValue = nil
	for _, tbl in ipairs({ Config.Pilze, Config.Fische, Config.Muscheln }) do
		for _, entry in ipairs(tbl) do
			if entry.name == materialName then
				sellValue = entry.sell
				break
			end
		end
		if sellValue then break end
	end

	if not sellValue then
		sellMaterialRemote:FireClient(player, false, "Unbekanntes Material")
		return
	end

	local ok = DataStore.removeMaterial(player, materialName, amount)
	if not ok then
		sellMaterialRemote:FireClient(player, false, "Nicht genug " .. materialName)
		return
	end

	local earned = sellValue * amount
	DataStore.addCash(player, earned)
	local data = DataStore.get(player)
	sellMaterialRemote:FireClient(player, true, earned, data and data.cash or 0)
end)

-- Spieler entfernt: Cooldowns leeren
Players.PlayerRemoving:Connect(function(player)
	cooldowns[player.UserId] = nil
end)

return CollectManager
