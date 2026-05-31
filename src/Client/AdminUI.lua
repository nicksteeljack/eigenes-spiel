-- AdminUI.lua (StarterPlayerScripts)
-- Admin-Panel: nur sichtbar fuer Spieler in Config.AdminUserIds.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config            = require(game.ReplicatedStorage.Shared.Config)

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes   = ReplicatedStorage:WaitForChild("Remotes")
local adminRemote = remotes:WaitForChild("AdminCommand")

local AdminUI = {}

-- Pruefe ob dieser Spieler Admin ist
local function isAdmin()
	for _, id in ipairs(Config.AdminUserIds) do
		if player.UserId == id then return true end
	end
	return false
end

if not isAdmin() then return AdminUI end -- Kein Admin: nichts aufbauen

local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "AdminUI"
screenGui.ResetOnSpawn   = false
screenGui.IgnoreGuiInset = true
screenGui.Parent         = playerGui

-- Oeffnen-Button oben rechts
local openBtn = Instance.new("TextButton")
openBtn.Size             = UDim2.new(0, 100, 0, 35)
openBtn.Position         = UDim2.new(1, -110, 0, 55)
openBtn.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
openBtn.BorderSizePixel  = 0
openBtn.Font             = Enum.Font.GothamBold
openBtn.TextSize         = 13
openBtn.TextColor3       = Color3.fromRGB(255,255,255)
openBtn.Text             = "⚙ ADMIN"
openBtn.Parent           = screenGui
local c1 = Instance.new("UICorner"); c1.CornerRadius = UDim.new(0,6); c1.Parent = openBtn

-- Fenster
local window = Instance.new("Frame")
window.Size             = UDim2.new(0, 420, 0, 520)
window.Position         = UDim2.new(1, -430, 0, 95)
window.BackgroundColor3 = Color3.fromRGB(15, 10, 10)
window.BorderSizePixel  = 0
window.Visible          = false
window.Parent           = screenGui
local wc = Instance.new("UICorner"); wc.CornerRadius = UDim.new(0,10); wc.Parent = window

local title = Instance.new("TextLabel")
title.Size             = UDim2.new(1, 0, 0, 40)
title.BackgroundTransparency = 1
title.TextColor3       = Color3.fromRGB(255, 80, 80)
title.Font             = Enum.Font.GothamBold
title.TextSize         = 18
title.Text             = "⚙ Admin Panel"
title.Parent           = window

local closeBtn = Instance.new("TextButton")
closeBtn.Size             = UDim2.new(0, 30, 0, 30)
closeBtn.Position         = UDim2.new(1, -35, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(180,50,50)
closeBtn.BorderSizePixel  = 0
closeBtn.Font             = Enum.Font.GothamBold
closeBtn.TextSize         = 16
closeBtn.TextColor3       = Color3.fromRGB(255,255,255)
closeBtn.Text             = "✕"
closeBtn.Parent           = window
local c2 = Instance.new("UICorner"); c2.CornerRadius = UDim.new(0,4); c2.Parent = closeBtn

-- Hilfsfunktion: Admin-Button erstellen
local function makeBtn(text, color, posY, callback)
	local btn = Instance.new("TextButton")
	btn.Size             = UDim2.new(1, -20, 0, 38)
	btn.Position         = UDim2.new(0, 10, 0, posY)
	btn.BackgroundColor3 = color
	btn.BorderSizePixel  = 0
	btn.Font             = Enum.Font.GothamBold
	btn.TextSize         = 13
	btn.TextColor3       = Color3.fromRGB(255,255,255)
	btn.Text             = text
	btn.Parent           = window
	local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0,6); bc.Parent = btn
	btn.MouseButton1Click:Connect(callback)
	return btn
end

-- Eingabefeld
local function makeInput(placeholder, posY)
	local box = Instance.new("TextBox")
	box.Size             = UDim2.new(1, -20, 0, 32)
	box.Position         = UDim2.new(0, 10, 0, posY)
	box.BackgroundColor3 = Color3.fromRGB(35, 25, 25)
	box.BorderSizePixel  = 0
	box.Font             = Enum.Font.Gotham
	box.TextSize         = 13
	box.TextColor3       = Color3.fromRGB(220, 220, 220)
	box.PlaceholderText  = placeholder
	box.PlaceholderColor3 = Color3.fromRGB(100,100,100)
	box.ClearTextOnFocus = false
	box.Parent           = window
	local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0,5); bc.Parent = box
	return box
end

-- Snap-Auswahl
local snapLabel = Instance.new("TextLabel")
snapLabel.Size             = UDim2.new(1, -20, 0, 22)
snapLabel.Position         = UDim2.new(0, 10, 0, 48)
snapLabel.BackgroundTransparency = 1
snapLabel.TextColor3       = Color3.fromRGB(180,180,180)
snapLabel.Font             = Enum.Font.GothamBold
snapLabel.TextSize         = 12
snapLabel.TextXAlignment   = Enum.TextXAlignment.Left
snapLabel.Text             = "SNAP"
snapLabel.Parent           = window

local snapInput = makeInput("Snap-Name (z.B. Disco)", 70)

makeBtn("▶ Snap starten", Color3.fromRGB(80, 150, 80), 106, function()
	adminRemote:FireServer({ cmd = "StartSnap", snapName = snapInput.Text })
end)
makeBtn("■ Alle Snaps stoppen", Color3.fromRGB(100, 60, 60), 148, function()
	adminRemote:FireServer({ cmd = "StopAllSnaps" })
end)

-- Trennlinie
local sep1 = Instance.new("Frame")
sep1.Size             = UDim2.new(1, -20, 0, 1)
sep1.Position         = UDim2.new(0, 10, 0, 196)
sep1.BackgroundColor3 = Color3.fromRGB(60, 40, 40)
sep1.BorderSizePixel  = 0
sep1.Parent           = window

-- Spieler-Verwaltung
local playerLabel = Instance.new("TextLabel")
playerLabel.Size             = UDim2.new(1, -20, 0, 22)
playerLabel.Position         = UDim2.new(0, 10, 0, 202)
playerLabel.BackgroundTransparency = 1
playerLabel.TextColor3       = Color3.fromRGB(180,180,180)
playerLabel.Font             = Enum.Font.GothamBold
playerLabel.TextSize         = 12
playerLabel.TextXAlignment   = Enum.TextXAlignment.Left
playerLabel.Text             = "SPIELER-VERWALTUNG"
playerLabel.Parent           = window

local userIdInput = makeInput("UserID des Spielers", 226)
local coinsInput  = makeInput("Coins-Menge", 262)

makeBtn("Coins an Spieler geben", Color3.fromRGB(50, 100, 180), 298, function()
	local uid    = tonumber(userIdInput.Text)
	local amount = tonumber(coinsInput.Text) or 0
	adminRemote:FireServer({ cmd = "GiveCoins", targetUserId = uid, amount = amount })
end)
makeBtn("Coins an ALLE geben", Color3.fromRGB(30, 80, 160), 340, function()
	local amount = tonumber(coinsInput.Text) or 0
	adminRemote:FireServer({ cmd = "GiveCoins", amount = amount })
end)
makeBtn("Spieler kicken", Color3.fromRGB(160, 60, 60), 382, function()
	local uid = tonumber(userIdInput.Text)
	adminRemote:FireServer({ cmd = "Kick", targetUserId = uid, reason = "Vom Admin gekickt" })
end)
makeBtn("Godmode (Spieler)", Color3.fromRGB(80, 80, 80), 424, function()
	local uid = tonumber(userIdInput.Text)
	adminRemote:FireServer({ cmd = "GodmodePlayer", targetUserId = uid, enabled = true })
end)
makeBtn("Godmode ALLE", Color3.fromRGB(60, 60, 60), 466, function()
	adminRemote:FireServer({ cmd = "GodmodeAll", enabled = true })
end)

openBtn.MouseButton1Click:Connect(function()
	window.Visible = not window.Visible
end)
closeBtn.MouseButton1Click:Connect(function()
	window.Visible = false
end)

adminRemote.OnClientEvent:Connect(function(result)
	local HUD = require(script.Parent.HUD)
	if result.success then
		HUD.notify("Admin: OK", Color3.fromRGB(100, 255, 100))
	else
		HUD.notify("Admin Fehler: " .. tostring(result.msg), Color3.fromRGB(255, 100, 100))
	end
end)

return AdminUI
