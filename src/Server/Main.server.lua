-- Main.server.lua (ServerScriptService)
-- Einstiegspunkt: erstellt alle RemoteEvents und laedt alle Manager.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Remote-Ordner anlegen
local remotes = Instance.new("Folder")
remotes.Name  = "Remotes"
remotes.Parent = ReplicatedStorage

local remoteNames = {
	-- DataStore / Cash
	"UpdateCash",
	"UpdateInventory",
	-- Brainrots
	"CatchBrainrot",
	"BrainrotSpawned",
	"BrainrotDespawned",
	-- Base
	"UpgradeBaseSlot",
	-- Sammeln
	"Collect",
	"SellMaterial",
	-- Traits
	"ApplyTrait",
	"IncubatorStatus",
	-- Rebirth
	"Rebirth",
	-- Combat
	"Attack",
	"PlayerDied",
	-- Trade
	"Trade",
	-- Snaps
	"SnapEvent",
	-- Shop
	"BuyItem",
	-- Admin
	"AdminCommand",
}

for _, name in ipairs(remoteNames) do
	local re = Instance.new("RemoteEvent")
	re.Name  = name
	re.Parent = remotes
end

-- Shared-Ordner in ReplicatedStorage
local shared = Instance.new("Folder")
shared.Name  = "Shared"
shared.Parent = ReplicatedStorage

-- Alle Server-Manager laden (Reihenfolge beachten!)
require(script.Parent.DataStore)
require(script.Parent.ZoneManager)
require(script.Parent.BrainrotSpawner)
require(script.Parent.BaseManager)
require(script.Parent.CollectManager)
require(script.Parent.TraitManager)
require(script.Parent.RebirthManager)
require(script.Parent.CombatManager)
require(script.Parent.TradeManager)
require(script.Parent.SnapManager)
require(script.Parent.GamepassManager)
require(script.Parent.AdminManager)

print("[Server] Alle Manager geladen. Spiel laeuft!")
