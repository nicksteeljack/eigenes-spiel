-- GamepassManager.lua (ServerScriptService)
-- Prueft beim Joinen ob ein Spieler Gamepasses besitzt und traegt sie ins DataStore ein.

local Players           = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local Config            = require(game.ReplicatedStorage.Shared.Config)
local DataStore         = require(script.Parent.DataStore)

local function checkGamepasses(player)
	local data = DataStore.get(player)
	if not data then return end

	for passKey, passCfg in pairs(Config.Gamepasses) do
		if passCfg.id and passCfg.id ~= 0 then
			local ok, owned = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passCfg.id)
			end)
			if ok and owned then
				data.gamepasses[passKey] = true
			end
		end
	end
end

Players.PlayerAdded:Connect(function(player)
	-- Kurz warten bis DataStore geladen ist
	task.wait(3)
	checkGamepasses(player)
end)

-- Gamepass wird waehrend der Session gekauft
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
	if not purchased then return end
	local data = DataStore.get(player)
	if not data then return end

	for passKey, passCfg in pairs(Config.Gamepasses) do
		if passCfg.id == passId then
			data.gamepasses[passKey] = true
			break
		end
	end
end)

return {}
