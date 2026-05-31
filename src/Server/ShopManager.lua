-- ShopManager.lua (ServerScriptService)
-- Verarbeitet Kauf-Anfragen vom Shop-Client.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config            = require(game.ReplicatedStorage.Shared.Config)
local DataStore         = require(script.Parent.DataStore)

local remotes    = ReplicatedStorage:WaitForChild("Remotes")
local buyRemote  = remotes:WaitForChild("BuyItem")
local updateCashRemote = remotes:WaitForChild("UpdateCash")

buyRemote.OnServerEvent:Connect(function(player, request)
	if not request then return end

	local data = DataStore.get(player)
	if not data then return end

	local itemKey  = request.itemKey
	local itemType = request.itemType

	if itemType == "Werkzeug" then
		local cfg = Config.Werkzeuge[itemKey]
		if not cfg then
			buyRemote:FireClient(player, false, "Unbekanntes Werkzeug")
			return
		end

		-- Bereits vorhanden?
		if itemKey == "Koeder" then
			-- Koeder ist Verbrauchsitem: einfach kaufen
			if data.cash < cfg.price then
				buyRemote:FireClient(player, false, "Nicht genug $")
				return
			end
			DataStore.addCash(player, -cfg.price)
			DataStore.addMaterial(player, "Koeder", 10) -- 10 Stueck pro Kauf
			buyRemote:FireClient(player, true, "10x Koeder gekauft")

		elseif itemKey == "Schaufel" then
			if data.cash < cfg.price then
				buyRemote:FireClient(player, false, "Nicht genug $")
				return
			end
			DataStore.addCash(player, -cfg.price)
			data.inventory.Schaufel = cfg.breakAfter or 25
			buyRemote:FireClient(player, true, "Schaufel gekauft")

		else
			-- Permanentes Werkzeug: nur einmal kaufbar
			if data.inventory[itemKey] then
				buyRemote:FireClient(player, false, "Bereits vorhanden")
				return
			end
			if data.cash < cfg.price then
				buyRemote:FireClient(player, false, "Nicht genug $")
				return
			end
			DataStore.addCash(player, -cfg.price)
			data.inventory[itemKey] = true
			buyRemote:FireClient(player, true, itemKey .. " gekauft")
		end

	elseif itemType == "Waffe" then
		local weaponCfg = nil
		for _, w in ipairs(Config.Waffen) do
			if w.name == itemKey then weaponCfg = w; break end
		end
		if not weaponCfg then
			buyRemote:FireClient(player, false, "Unbekannte Waffe")
			return
		end

		-- Bereits vorhanden?
		for _, w in ipairs(data.waffen) do
			if w == itemKey then
				buyRemote:FireClient(player, false, "Bereits vorhanden")
				return
			end
		end

		-- Bezahlung
		if weaponCfg.priceCash > 0 then
			if data.cash < weaponCfg.priceCash then
				buyRemote:FireClient(player, false, "Nicht genug $")
				return
			end
			DataStore.addCash(player, -weaponCfg.priceCash)
		elseif weaponCfg.priceCoin > 0 then
			if data.eventCoins < weaponCfg.priceCoin then
				buyRemote:FireClient(player, false, "Nicht genug Event Coins")
				return
			end
			DataStore.addCoins(player, -weaponCfg.priceCoin)
		end

		table.insert(data.waffen, itemKey)
		buyRemote:FireClient(player, true, itemKey .. " gekauft")
	else
		buyRemote:FireClient(player, false, "Unbekannter Typ")
	end

	updateCashRemote:FireClient(player, data.cash)
end)

return {}
