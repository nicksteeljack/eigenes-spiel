-- SnapManager.lua (ServerScriptService)
-- Admin startet/stoppt Snaps: Effekte, Songs, Event-Traits werden gleichzeitig aktiviert.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config            = require(game.ReplicatedStorage.Shared.Config)

local remotes     = ReplicatedStorage:WaitForChild("Remotes")
local snapRemote  = remotes:WaitForChild("SnapEvent") -- Server -> Client: { active, snapName, effects, songs }

local SnapManager = {}

-- Aktuell aktive Snaps: { [snapName] = true }
local activeSnaps = {}

-- Snap starten
function SnapManager.startSnap(snapName)
	local snapCfg = nil
	for _, s in ipairs(Config.Snaps) do
		if s.name == snapName then snapCfg = s; break end
	end
	if not snapCfg then
		warn("[SnapManager] Unbekannter Snap: " .. tostring(snapName))
		return false
	end

	-- Vorherige Snaps loeschen (alle gleichzeitig stoppen)
	for name in pairs(activeSnaps) do
		SnapManager.stopSnap(name)
	end

	activeSnaps[snapName] = true

	snapRemote:FireAllClients({
		active   = true,
		snapName = snapName,
		effects  = snapCfg.effects,
		songs    = snapCfg.songs,
		traits   = snapCfg.traits,
	})
	return true
end

-- Snap stoppen
function SnapManager.stopSnap(snapName)
	if not activeSnaps[snapName] then return end
	activeSnaps[snapName] = nil

	snapRemote:FireAllClients({
		active   = false,
		snapName = snapName,
	})
end

-- Alle Snaps stoppen
function SnapManager.stopAll()
	for name in pairs(activeSnaps) do
		SnapManager.stopSnap(name)
	end
end

-- Prueft ob ein bestimmter Snap gerade aktiv ist
function SnapManager.isSnapActive(snapName)
	return activeSnaps[snapName] == true
end

-- Alle aktiven Snaps zurueckgeben
function SnapManager.getActive()
	local list = {}
	for name in pairs(activeSnaps) do
		table.insert(list, name)
	end
	return list
end

return SnapManager
