-- ZoneManager.lua (ServerScriptService)
-- Erkennt in welcher Zone ein Spieler steht und erzwingt Safe-Zone-Regeln.
-- Erwartet: In Workspace gibt es einen Ordner "Zones" mit Parts,
-- deren Name der Config-Zone entspricht (z.B. "Krankenhaus", "Park", "Runway").

local Players  = game:GetService("Players")
local Config   = require(game.ReplicatedStorage.Shared.Config)
local RunService = game:GetService("RunService")

local ZoneManager = {}

local playerZones = {} -- [userId] = zoneName

-- Liefert den Part-Ordner aus dem Workspace
local function getZoneParts()
	local folder = workspace:FindFirstChild("Zones")
	if not folder then
		warn("[ZoneManager] Kein 'Zones'-Ordner in Workspace gefunden!")
		return {}
	end
	return folder:GetChildren()
end

-- Prueft ob ein Punkt innerhalb eines Parts liegt
local function isInsidePart(position, part)
	local localPos = part.CFrame:PointToObjectSpace(position)
	local size     = part.Size / 2
	return math.abs(localPos.X) <= size.X
		and math.abs(localPos.Y) <= size.Y
		and math.abs(localPos.Z) <= size.Z
end

-- Gibt den Zonennamen zurueck in dem sich ein Spieler befindet (oder nil)
function ZoneManager.getZone(player)
	return playerZones[player.UserId]
end

-- Prueft ob PvP fuer diesen Spieler gerade erlaubt ist
function ZoneManager.isPvPAllowed(player)
	local zone = playerZones[player.UserId]
	if not zone then return true end -- ausserhalb = open world
	local zoneCfg = Config.Zones[zone]
	return zoneCfg == nil or zoneCfg.pvp == true
end

-- Hauptschleife: alle 0.5 Sekunden Zone aller Spieler pruefen
task.spawn(function()
	local zoneParts = getZoneParts()

	-- Zonen-Parts bei Bedarf neu laden wenn Workspace sich aendert
	workspace:GetPropertyChangedSignal("Name"):Connect(function()
		zoneParts = getZoneParts()
	end)

	while true do
		task.wait(0.5)

		-- Zone-Parts einmalig pro Tick aktualisieren falls Ordner neu
		local folder = workspace:FindFirstChild("Zones")
		if folder then
			zoneParts = folder:GetChildren()
		end

		for _, player in ipairs(Players:GetPlayers()) do
			local char = player.Character
			if not char then continue end
			local hrp = char:FindFirstChild("HumanoidRootPart")
			if not hrp then continue end

			local pos         = hrp.Position
			local foundZone   = nil

			for _, part in ipairs(zoneParts) do
				if part:IsA("BasePart") and isInsidePart(pos, part) then
					foundZone = part.Name
					break
				end
			end

			local prev = playerZones[player.UserId]
			playerZones[player.UserId] = foundZone

			-- Zonen-Wechsel-Ereignis feuern
			if prev ~= foundZone then
				ZoneManager.onZoneChanged(player, prev, foundZone)
			end
		end
	end
end)

-- Wird aufgerufen wenn ein Spieler die Zone wechselt
function ZoneManager.onZoneChanged(player, fromZone, toZone)
	local zoneCfg = toZone and Config.Zones[toZone]
	local isSafe  = zoneCfg and not zoneCfg.pvp

	-- Spieler in Safe-Zone: Unverwundbarkeit aktivieren
	local char = player.Character
	if char then
		local humanoid = char:FindFirstChild("Humanoid")
		if humanoid then
			if isSafe then
				-- Safe-Zone: kein Schaden moeglich
				humanoid:SetAttribute("InSafeZone", true)
			else
				humanoid:SetAttribute("InSafeZone", false)
			end
		end
	end
end

-- Spieler entfernt: Eintrag loeschen
Players.PlayerRemoving:Connect(function(player)
	playerZones[player.UserId] = nil
end)

return ZoneManager
