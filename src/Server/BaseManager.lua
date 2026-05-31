-- BaseManager.lua (ServerScriptService)
-- Verwaltet die Spieler-Base: Einnahmen-Ticker, Slot-Upgrades, Base-Skins.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config            = require(game.ReplicatedStorage.Shared.Config)
local DataStore         = require(script.Parent.DataStore)

local BaseManager = {}

local remotes          = ReplicatedStorage:WaitForChild("Remotes")
local upgradeSlotRemote = remotes:WaitForChild("UpgradeBaseSlot")
local updateCashRemote  = remotes:WaitForChild("UpdateCash")

-- Passives Einkommen eines Spielers auszahlen
local function tickPlayer(player)
	local data = DataStore.get(player)
	if not data then return end

	local dph         = DataStore.getTotalDPH(player)
	local perTick     = dph / 60 -- $/h -> $/min (Ticker laeuft jede Minute)

	if perTick <= 0 then return end

	DataStore.addCash(player, perTick)
	updateCashRemote:FireClient(player, data.cash)
end

-- Slot-Upgrade-Request vom Client
upgradeSlotRemote.OnServerEvent:Connect(function(player)
	local data = DataStore.get(player)
	if not data then return end

	local currentSlots = data.baseSlots
	if currentSlots >= Config.Base.maxSlots then
		upgradeSlotRemote:FireClient(player, false, "Maximale Slot-Anzahl erreicht")
		return
	end

	local cost = Config.Base.slotUpgradeCost[currentSlots]
	if not cost then
		upgradeSlotRemote:FireClient(player, false, "Keine Kosten definiert")
		return
	end

	if data.cash < cost then
		upgradeSlotRemote:FireClient(player, false, "Nicht genug $")
		return
	end

	DataStore.addCash(player, -cost)
	DataStore.set(player, "baseSlots", currentSlots + 1)
	updateCashRemote:FireClient(player, data.cash)
	upgradeSlotRemote:FireClient(player, true, data.baseSlots)
end)

-- Income-Ticker: laeuft fuer alle Spieler gleichzeitig
task.spawn(function()
	while true do
		task.wait(Config.Base.cashTickerInterval)
		for _, player in ipairs(Players:GetPlayers()) do
			tickPlayer(player)
		end
	end
end)

-- Sofortige erste Zahlung wenn Spieler joint (nach kurzem Delay damit DataStore geladen ist)
Players.PlayerAdded:Connect(function(player)
	task.wait(3)
	tickPlayer(player)
end)

return BaseManager
