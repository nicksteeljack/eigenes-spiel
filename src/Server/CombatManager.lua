-- CombatManager.lua (ServerScriptService)
-- Verwaltet PvP: HP, Schaden, Tod und Respawn-Gebuehr.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config            = require(game.ReplicatedStorage.Shared.Config)
local DataStore         = require(script.Parent.DataStore)
local ZoneManager       = require(script.Parent.ZoneManager)

local remotes       = ReplicatedStorage:WaitForChild("Remotes")
local attackRemote  = remotes:WaitForChild("Attack")   -- { targetUserId, weaponName }
local deathRemote   = remotes:WaitForChild("PlayerDied")
local updateCashRemote = remotes:WaitForChild("UpdateCash")

-- Unverwundbarkeits-Override durch Admin
local godmodeAll     = false
local godmodePlayers = {} -- [userId] = true

-- Weapon-Config nach Name suchen
local function findWeapon(name)
	for _, w in ipairs(Config.Waffen) do
		if w.name == name then return w end
	end
end

-- Spieler hat eine Waffe in seinem Inventar?
local function hasWeapon(player, weaponName)
	local data = DataStore.get(player)
	if not data then return false end
	for _, w in ipairs(data.waffen) do
		if w == weaponName then return true end
	end
	return false
end

-- Tod-Logik: Gebuehr abziehen, Respawn am Krankenhaus
local function handleDeath(victim)
	local data = DataStore.get(victim)
	if not data then return end

	-- Gebuehr: 10% des stündlichen Einkommens
	local dph   = DataStore.getTotalDPH(victim)
	local fee   = math.floor(dph * Config.DeathFee)
	DataStore.addCash(victim, -fee)

	local char = victim.Character
	if char then
		local humanoid = char:FindFirstChild("Humanoid")
		if humanoid then
			-- Respawn am Krankenhaus (Roblox-Standard-Spawn-Mechanik genuegt hier)
			humanoid.Health = 0
		end
	end

	updateCashRemote:FireClient(victim, data.cash)
	deathRemote:FireClient(victim, { fee = fee })
end

-- Angriffs-Request vom Client
attackRemote.OnServerEvent:Connect(function(attacker, request)
	if not request then return end

	local targetId  = request.targetUserId
	local weaponName = request.weaponName

	-- Godmode pruefen
	if godmodeAll or godmodePlayers[attacker.UserId] then return end

	-- Waffe vorhanden?
	if not hasWeapon(attacker, weaponName) then
		attackRemote:FireClient(attacker, { success = false, msg = "Waffe nicht im Inventar" })
		return
	end

	-- Ziel-Spieler finden
	local target = Players:GetPlayerByUserId(targetId)
	if not target then return end

	-- Godmode Ziel
	if godmodeAll or godmodePlayers[targetId] then return end

	-- PvP erlaubt in der Zone des Angreifers UND des Ziels?
	if not ZoneManager.isPvPAllowed(attacker) or not ZoneManager.isPvPAllowed(target) then
		attackRemote:FireClient(attacker, { success = false, msg = "Kein PvP in dieser Zone" })
		return
	end

	-- Safe-Zone-Attribut pruefen (redundante Sicherung)
	local targetChar = target.Character
	if targetChar then
		local humanoid = targetChar:FindFirstChild("Humanoid")
		if humanoid and humanoid:GetAttribute("InSafeZone") then
			attackRemote:FireClient(attacker, { success = false, msg = "Ziel ist in einer Safe-Zone" })
			return
		end
	end

	-- Schaden anwenden
	local weaponCfg = findWeapon(weaponName)
	if not weaponCfg then return end

	if targetChar then
		local humanoid = targetChar:FindFirstChild("Humanoid")
		if humanoid and humanoid.Health > 0 then
			humanoid:TakeDamage(weaponCfg.damage)
			if humanoid.Health <= 0 then
				handleDeath(target)
			end
		end
	end
end)

-- Humanoid stirbt (z.B. durch Fall oder andere Ursachen)
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(char)
		local humanoid = char:WaitForChild("Humanoid")
		humanoid.Died:Connect(function()
			handleDeath(player)
		end)
	end)
end)

-- Admin-Funktionen
local CombatManager = {}

function CombatManager.setGodmodeAll(enabled)
	godmodeAll = enabled
end

function CombatManager.setGodmodePlayer(userId, enabled)
	godmodePlayers[userId] = enabled or nil
end

return CombatManager
