-- Main.client.lua (StarterPlayerScripts)
-- Startet alle Client-Module und verbindet globale Remote-Events.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player  = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Alle Client-Module laden
local HUD        = require(script.Parent.HUD)
local BaseUI     = require(script.Parent.BaseUI)
local CollectUI  = require(script.Parent.CollectUI)
local BrainrotUI = require(script.Parent.BrainrotUI)
local RebirthUI  = require(script.Parent.RebirthUI)
local ShopUI     = require(script.Parent.ShopUI)
local TradeUI    = require(script.Parent.TradeUI)
local AdminUI    = require(script.Parent.AdminUI)

-- Geld-Update vom Server
remotes:WaitForChild("UpdateCash").OnClientEvent:Connect(function(newCash)
	HUD.setCash(newCash)
end)

-- Snap-Events
remotes:WaitForChild("SnapEvent").OnClientEvent:Connect(function(data)
	if data.active then
		-- Sound abspielen
		if data.songs and data.songs[1] then
			local sound = Instance.new("Sound")
			sound.SoundId = data.songs[1]
			sound.Parent  = workspace
			sound:Play()
		end
	end
end)

print("[Client] Alle Module geladen.")
