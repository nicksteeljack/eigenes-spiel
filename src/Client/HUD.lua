-- HUD.lua (StarterPlayerScripts)
-- Zeigt Geld, Rebirth-Level und Rebirth-Multiplikator oben auf dem Bildschirm.

local Players       = game:GetService("Players")
local player        = Players.LocalPlayer
local playerGui     = player:WaitForChild("PlayerGui")

local HUD = {}

-- GUI aufbauen
local screenGui = Instance.new("ScreenGui")
screenGui.Name            = "HUD"
screenGui.ResetOnSpawn    = false
screenGui.IgnoreGuiInset  = true
screenGui.Parent          = playerGui

-- Hintergrund-Leiste oben
local topBar = Instance.new("Frame")
topBar.Size            = UDim2.new(1, 0, 0, 50)
topBar.Position        = UDim2.new(0, 0, 0, 0)
topBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
topBar.BackgroundTransparency = 0.3
topBar.BorderSizePixel = 0
topBar.Parent          = screenGui

-- Geld-Anzeige
local cashLabel = Instance.new("TextLabel")
cashLabel.Size             = UDim2.new(0, 300, 1, 0)
cashLabel.Position         = UDim2.new(0, 20, 0, 0)
cashLabel.BackgroundTransparency = 1
cashLabel.TextColor3       = Color3.fromRGB(255, 220, 50)
cashLabel.Font             = Enum.Font.GothamBold
cashLabel.TextSize         = 22
cashLabel.TextXAlignment   = Enum.TextXAlignment.Left
cashLabel.Text             = "$ 0"
cashLabel.Parent           = topBar

-- Rebirth-Anzeige rechts
local rebirthLabel = Instance.new("TextLabel")
rebirthLabel.Size             = UDim2.new(0, 300, 1, 0)
rebirthLabel.Position         = UDim2.new(1, -320, 0, 0)
rebirthLabel.BackgroundTransparency = 1
rebirthLabel.TextColor3       = Color3.fromRGB(180, 100, 255)
rebirthLabel.Font             = Enum.Font.GothamBold
rebirthLabel.TextSize         = 20
rebirthLabel.TextXAlignment   = Enum.TextXAlignment.Right
rebirthLabel.Text             = "Rebirth 0  ·  1x"
rebirthLabel.Parent           = topBar

-- Benachrichtigungs-Label (kurze Meldungen wie "+50$")
local notifLabel = Instance.new("TextLabel")
notifLabel.Size             = UDim2.new(0, 400, 0, 40)
notifLabel.Position         = UDim2.new(0.5, -200, 0, 60)
notifLabel.BackgroundTransparency = 1
notifLabel.TextColor3       = Color3.fromRGB(255, 255, 255)
notifLabel.Font             = Enum.Font.GothamBold
notifLabel.TextSize         = 20
notifLabel.TextStrokeTransparency = 0
notifLabel.Text             = ""
notifLabel.Visible          = false
notifLabel.Parent           = screenGui

local notifTween = nil

-- Kurze Benachrichtigung anzeigen (verschwindet nach 2 Sekunden)
function HUD.notify(text, color)
	if notifTween then notifTween:Cancel() end
	notifLabel.Text       = text
	notifLabel.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	notifLabel.Visible    = true
	notifLabel.TextTransparency = 0

	local TweenService = game:GetService("TweenService")
	notifTween = TweenService:Create(notifLabel,
		TweenInfo.new(2, Enum.EasingStyle.Linear),
		{ TextTransparency = 1 }
	)
	notifTween:Play()
	notifTween.Completed:Connect(function()
		notifLabel.Visible = false
	end)
end

-- Geld-Anzeige aktualisieren
function HUD.setCash(amount)
	cashLabel.Text = "$ " .. math.floor(amount)
end

-- Rebirth-Anzeige aktualisieren
function HUD.setRebirth(level, multiplier)
	rebirthLabel.Text = "Rebirth " .. level .. "  ·  " .. multiplier .. "x"
end

return HUD
