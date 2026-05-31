-- RebirthManager.lua (ServerScriptService)
-- Verwaltet das Rebirth-System: Materialien einloesen, Stufe steigen, $ zuruecksetzen.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config            = require(game.ReplicatedStorage.Shared.Config)
local DataStore         = require(script.Parent.DataStore)

local remotes        = ReplicatedStorage:WaitForChild("Remotes")
local rebirthRemote  = remotes:WaitForChild("Rebirth") -- { materialsToSpend = { ["Steinpilz"] = 5, ... } }
local updateCashRemote = remotes:WaitForChild("UpdateCash")

-- Punkt-Wert eines Materials ermitteln
local function getMaterialPoints(materialName)
	for _, tbl in ipairs({ Config.Pilze, Config.Fische, Config.Muscheln }) do
		for _, entry in ipairs(tbl) do
			if entry.name == materialName then
				return entry.rebirthPoints
			end
		end
	end
	return 0
end

-- Benoetigte Punkte fuer naechste Rebirth-Stufe
local function pointsForNextLevel(currentLevel)
	local next = Config.Rebirth.levels[currentLevel + 1]
	return next and next.points or nil
end

rebirthRemote.OnServerEvent:Connect(function(player, request)
	if not request or not request.materialsToSpend then return end

	local data = DataStore.get(player)
	if not data then return end

	local currentLevel = data.rebirthLevel or 0
	if currentLevel >= Config.Rebirth.maxLevel then
		rebirthRemote:FireClient(player, { success = false, msg = "Maximale Rebirth-Stufe erreicht" })
		return
	end

	local needed = pointsForNextLevel(currentLevel)
	if not needed then
		rebirthRemote:FireClient(player, { success = false, msg = "Keine naechste Stufe definiert" })
		return
	end

	-- Punkte aus den gewaehlten Materialien berechnen
	local totalPoints = 0
	for materialName, amount in pairs(request.materialsToSpend) do
		if amount > 0 then
			local available = data.materials[materialName] or 0
			if available < amount then
				rebirthRemote:FireClient(player, { success = false, msg = "Nicht genug " .. materialName })
				return
			end
			totalPoints += getMaterialPoints(materialName) * amount
		end
	end

	-- Rebirth-Punkte bisher + neue Punkte
	local newTotal = (data.rebirthPoints or 0) + totalPoints

	if newTotal < needed then
		rebirthRemote:FireClient(player, {
			success  = false,
			msg      = "Zu wenig Punkte (" .. newTotal .. "/" .. needed .. ")",
			points   = newTotal,
			needed   = needed,
		})
		return
	end

	-- Materialien abziehen
	for materialName, amount in pairs(request.materialsToSpend) do
		DataStore.removeMaterial(player, materialName, amount)
	end

	-- Rebirth durchfuehren
	local newLevel = currentLevel + 1
	local leftoverPoints = newTotal - needed

	data.rebirthLevel  = newLevel
	data.rebirthPoints = leftoverPoints
	data.cash          = 0 -- $ auf 0 zuruecksetzen
	data.stats.rebirths = (data.stats.rebirths or 0) + 1

	updateCashRemote:FireClient(player, 0)

	local newMultiplier = Config.Rebirth.levels[newLevel].multiplier
	rebirthRemote:FireClient(player, {
		success     = true,
		newLevel    = newLevel,
		multiplier  = newMultiplier,
		leftover    = leftoverPoints,
	})
end)

return {}
