-- AdminManager.lua (ServerScriptService)
-- Admin-Panel-Logik: nur fuer Owner (UserIds aus Config).

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config            = require(game.ReplicatedStorage.Shared.Config)
local DataStore         = require(script.Parent.DataStore)
local SnapManager       = require(script.Parent.SnapManager)
local CombatManager     = require(script.Parent.CombatManager)

local remotes      = ReplicatedStorage:WaitForChild("Remotes")
local adminRemote  = remotes:WaitForChild("AdminCommand")
-- Nachrichten-Format: { cmd, ... }

local function isAdmin(player)
	for _, id in ipairs(Config.AdminUserIds) do
		if player.UserId == id then return true end
	end
	return false
end

adminRemote.OnServerEvent:Connect(function(player, request)
	if not isAdmin(player) then
		adminRemote:FireClient(player, { success = false, msg = "Kein Zugriff" })
		return
	end
	if not request then return end

	local cmd = request.cmd

	-- SNAP START / STOP
	if cmd == "StartSnap" then
		local ok = SnapManager.startSnap(request.snapName)
		adminRemote:FireClient(player, { success = ok })

	elseif cmd == "StopSnap" then
		SnapManager.stopSnap(request.snapName)
		adminRemote:FireClient(player, { success = true })

	elseif cmd == "StopAllSnaps" then
		SnapManager.stopAll()
		adminRemote:FireClient(player, { success = true })

	-- GODMODE
	elseif cmd == "GodmodeAll" then
		CombatManager.setGodmodeAll(request.enabled)
		adminRemote:FireClient(player, { success = true })

	elseif cmd == "GodmodePlayer" then
		local target = Players:GetPlayerByUserId(request.targetUserId)
		if target then
			CombatManager.setGodmodePlayer(target.UserId, request.enabled)
			adminRemote:FireClient(player, { success = true })
		else
			adminRemote:FireClient(player, { success = false, msg = "Spieler nicht gefunden" })
		end

	-- SPIELER KICKEN
	elseif cmd == "Kick" then
		local target = Players:GetPlayerByUserId(request.targetUserId)
		if target then
			target:Kick(request.reason or "Vom Admin gekickt")
			adminRemote:FireClient(player, { success = true })
		else
			adminRemote:FireClient(player, { success = false, msg = "Spieler nicht gefunden" })
		end

	-- EVENT COINS VERGEBEN
	elseif cmd == "GiveCoins" then
		local amount = request.amount or 0
		if request.targetUserId then
			-- Einzelner Spieler
			local target = Players:GetPlayerByUserId(request.targetUserId)
			if target then
				DataStore.addCoins(target, amount)
				adminRemote:FireClient(player, { success = true })
			else
				adminRemote:FireClient(player, { success = false, msg = "Spieler nicht gefunden" })
			end
		else
			-- Alle Spieler
			for _, p in ipairs(Players:GetPlayers()) do
				DataStore.addCoins(p, amount)
			end
			adminRemote:FireClient(player, { success = true })
		end

	-- INVENTAR BEARBEITEN
	elseif cmd == "SetCash" then
		local target = Players:GetPlayerByUserId(request.targetUserId)
		if target then
			local data = DataStore.get(target)
			if data then
				data.cash = request.amount or 0
				adminRemote:FireClient(player, { success = true })
			end
		end

	-- BASE EINES SPIELERS LADEN (Daten senden)
	elseif cmd == "ViewBase" then
		local target = Players:GetPlayerByUserId(request.targetUserId)
		if target then
			local data = DataStore.get(target)
			adminRemote:FireClient(player, {
				success   = true,
				playerName = target.Name,
				brainrots = data and data.brainrots or {},
				cash      = data and data.cash or 0,
			})
		else
			adminRemote:FireClient(player, { success = false, msg = "Spieler nicht gefunden" })
		end

	-- EXTRA LUCK (Global-Attribut fuer Spawn-Gewichtung)
	elseif cmd == "SetExtraLuck" then
		-- Wird in BrainrotSpawner ausgelesen via workspace-Attribut
		workspace:SetAttribute("ExtraLuck", request.enabled and true or false)
		adminRemote:FireClient(player, { success = true })

	else
		adminRemote:FireClient(player, { success = false, msg = "Unbekannter Befehl: " .. tostring(cmd) })
	end
end)

return {}
