-- TradeManager.lua (ServerScriptService)
-- Zwei-Spieler-Handel: Brainrots, Items, Materialien, $ (keine Event Coins).

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStore         = require(script.Parent.DataStore)

local remotes        = ReplicatedStorage:WaitForChild("Remotes")
local tradeRemote    = remotes:WaitForChild("Trade")
-- Nachrichten-Typen vom Client:
--   { action = "Request",  targetUserId }
--   { action = "Accept",   tradeId }
--   { action = "Decline",  tradeId }
--   { action = "Offer",    tradeId, offer = { cash, brainrotIndices[], materials } }
--   { action = "Confirm",  tradeId }
--   { action = "Cancel",   tradeId }

-- Aktive Trades: [tradeId] = { playerA, playerB, offerA, offerB, confirmedA, confirmedB }
local trades    = {}
local tradeCounter = 0

local function newTradeId()
	tradeCounter += 1
	return "trade_" .. tradeCounter
end

local function getTradeByPlayer(player)
	for id, trade in pairs(trades) do
		if trade.playerA == player or trade.playerB == player then
			return id, trade
		end
	end
end

local function cancelTrade(tradeId, reason)
	local trade = trades[tradeId]
	if not trade then return end
	tradeRemote:FireClient(trade.playerA, { action = "Cancelled", reason = reason })
	tradeRemote:FireClient(trade.playerB, { action = "Cancelled", reason = reason })
	trades[tradeId] = nil
end

-- Transfer-Logik: Angebote tauschen
local function executeTrade(tradeId)
	local trade = trades[tradeId]
	if not trade then return end

	local a, b     = trade.playerA, trade.playerB
	local offerA   = trade.offerA or {}
	local offerB   = trade.offerB or {}
	local dataA    = DataStore.get(a)
	local dataB    = DataStore.get(b)

	if not dataA or not dataB then
		cancelTrade(tradeId, "Spieler-Daten nicht verfuegbar")
		return
	end

	-- Validierung: Hat A wirklich was er anbietet?
	if (offerA.cash or 0) > dataA.cash then
		cancelTrade(tradeId, "Spieler A hat nicht genug $")
		return
	end
	if (offerB.cash or 0) > dataB.cash then
		cancelTrade(tradeId, "Spieler B hat nicht genug $")
		return
	end

	-- $ transferieren
	DataStore.addCash(a, -(offerA.cash or 0))
	DataStore.addCash(b,  (offerA.cash or 0))
	DataStore.addCash(b, -(offerB.cash or 0))
	DataStore.addCash(a,  (offerB.cash or 0))

	-- Brainrots transferieren (von A zu B)
	local brainrotsFromA = {}
	if offerA.brainrotIndices then
		-- Rueckwaerts iterieren damit Indices stimmen
		local sorted = table.clone(offerA.brainrotIndices)
		table.sort(sorted, function(x, y) return x > y end)
		for _, idx in ipairs(sorted) do
			local br = table.remove(dataA.brainrots, idx)
			if br then table.insert(brainrotsFromA, br) end
		end
	end
	local brainrotsFromB = {}
	if offerB.brainrotIndices then
		local sorted = table.clone(offerB.brainrotIndices)
		table.sort(sorted, function(x, y) return x > y end)
		for _, idx in ipairs(sorted) do
			local br = table.remove(dataB.brainrots, idx)
			if br then table.insert(brainrotsFromB, br) end
		end
	end
	for _, br in ipairs(brainrotsFromA) do table.insert(dataB.brainrots, br) end
	for _, br in ipairs(brainrotsFromB) do table.insert(dataA.brainrots, br) end

	-- Materialien transferieren
	if offerA.materials then
		for matName, amount in pairs(offerA.materials) do
			DataStore.removeMaterial(a, matName, amount)
			DataStore.addMaterial(b, matName, amount)
		end
	end
	if offerB.materials then
		for matName, amount in pairs(offerB.materials) do
			DataStore.removeMaterial(b, matName, amount)
			DataStore.addMaterial(a, matName, amount)
		end
	end

	tradeRemote:FireClient(a, { action = "Complete" })
	tradeRemote:FireClient(b, { action = "Complete" })
	trades[tradeId] = nil
end

tradeRemote.OnServerEvent:Connect(function(player, request)
	if not request then return end
	local action = request.action

	if action == "Request" then
		-- Neuen Trade anfragen
		local targetId = request.targetUserId
		local target   = Players:GetPlayerByUserId(targetId)
		if not target or target == player then return end

		-- Spieler bereits in Trade?
		if getTradeByPlayer(player) or getTradeByPlayer(target) then
			tradeRemote:FireClient(player, { action = "Error", msg = "Bereits in einem Trade" })
			return
		end

		local id = newTradeId()
		trades[id] = {
			playerA    = player,
			playerB    = target,
			offerA     = {},
			offerB     = {},
			confirmedA = false,
			confirmedB = false,
		}
		tradeRemote:FireClient(target, { action = "Incoming", tradeId = id, from = player.Name })

	elseif action == "Accept" then
		local trade = trades[request.tradeId]
		if not trade or trade.playerB ~= player then return end
		tradeRemote:FireClient(trade.playerA, { action = "Accepted", tradeId = request.tradeId })
		tradeRemote:FireClient(trade.playerB, { action = "Accepted", tradeId = request.tradeId })

	elseif action == "Decline" then
		cancelTrade(request.tradeId, "Abgelehnt")

	elseif action == "Offer" then
		local tradeId = request.tradeId
		local trade   = trades[tradeId]
		if not trade then return end
		-- Bestaetigung zuruecksetzen wenn Angebot geaendert wird
		trade.confirmedA = false
		trade.confirmedB = false
		if trade.playerA == player then
			trade.offerA = request.offer or {}
		else
			trade.offerB = request.offer or {}
		end
		-- Beide Seiten ueber neues Angebot informieren
		tradeRemote:FireClient(trade.playerA, { action = "OfferUpdated", tradeId = tradeId, offerA = trade.offerA, offerB = trade.offerB })
		tradeRemote:FireClient(trade.playerB, { action = "OfferUpdated", tradeId = tradeId, offerA = trade.offerA, offerB = trade.offerB })

	elseif action == "Confirm" then
		local tradeId = request.tradeId
		local trade   = trades[tradeId]
		if not trade then return end
		if trade.playerA == player then trade.confirmedA = true end
		if trade.playerB == player then trade.confirmedB = true end
		if trade.confirmedA and trade.confirmedB then
			executeTrade(tradeId)
		end

	elseif action == "Cancel" then
		cancelTrade(request.tradeId, "Abgebrochen")
	end
end)

-- Spieler verlaesst: offene Trades abbrechen
Players.PlayerRemoving:Connect(function(player)
	local tradeId = select(1, getTradeByPlayer(player))
	if tradeId then
		cancelTrade(tradeId, "Spieler hat das Spiel verlassen")
	end
end)

return {}
