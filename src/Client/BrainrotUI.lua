-- BrainrotUI.lua (StarterPlayerScripts)
-- Zeigt gespawnte Brainrots auf dem Runway an und ermoeglicht das Fangen per Klick.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes   = ReplicatedStorage:WaitForChild("Remotes")

local spawnedRemote  = remotes:WaitForChild("BrainrotSpawned")
local despawnRemote  = remotes:WaitForChild("BrainrotDespawned")
local catchRemote    = remotes:WaitForChild("CatchBrainrot")

local BrainrotUI = {}

-- Haupt-GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "BrainrotUI"
screenGui.ResetOnSpawn   = false
screenGui.IgnoreGuiInset = true
screenGui.Parent         = playerGui

-- Liste aktiver Brainrot-Karten: [id] = frame
local cards = {}

local RARITY_COLORS = {
	Common          = Color3.fromRGB(200, 200, 200),
	Rare            = Color3.fromRGB(100, 150, 255),
	["Secret Rare"] = Color3.fromRGB(255, 100, 220),
	OG              = Color3.fromRGB(255, 215, 0),
}

-- Brainrot-Karte erstellen (rechts am Bildschirm aufgelistet)
local function createCard(data, index)
	local rarityColor = RARITY_COLORS[data.rarity] or Color3.fromRGB(255,255,255)

	local card = Instance.new("Frame")
	card.Size              = UDim2.new(0, 220, 0, 90)
	card.Position          = UDim2.new(1, -240, 0, 60 + (index - 1) * 100)
	card.BackgroundColor3  = Color3.fromRGB(25, 25, 25)
	card.BackgroundTransparency = 0.15
	card.BorderSizePixel   = 0
	card.Parent            = screenGui

	-- Seltenheits-Farbstreifen links
	local stripe = Instance.new("Frame")
	stripe.Size             = UDim2.new(0, 5, 1, 0)
	stripe.BackgroundColor3 = rarityColor
	stripe.BorderSizePixel  = 0
	stripe.Parent           = card

	-- Name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size             = UDim2.new(1, -10, 0, 24)
	nameLabel.Position         = UDim2.new(0, 10, 0, 4)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextColor3       = rarityColor
	nameLabel.Font             = Enum.Font.GothamBold
	nameLabel.TextSize         = 14
	nameLabel.TextXAlignment   = Enum.TextXAlignment.Left
	nameLabel.TextTruncate     = Enum.TextTruncate.AtEnd
	nameLabel.Text             = data.name
	nameLabel.Parent           = card

	-- Seltenheit + Verkaufswert
	local infoLabel = Instance.new("TextLabel")
	infoLabel.Size             = UDim2.new(1, -10, 0, 18)
	infoLabel.Position         = UDim2.new(0, 10, 0, 28)
	infoLabel.BackgroundTransparency = 1
	infoLabel.TextColor3       = Color3.fromRGB(180, 180, 180)
	infoLabel.Font             = Enum.Font.Gotham
	infoLabel.TextSize         = 12
	infoLabel.TextXAlignment   = Enum.TextXAlignment.Left
	infoLabel.Text             = data.rarity .. "  ·  $" .. data.sell .. "  ·  " .. data.dph .. "$/h"
	infoLabel.Parent           = card

	-- Timer-Balken
	local timerBg = Instance.new("Frame")
	timerBg.Size             = UDim2.new(1, -10, 0, 6)
	timerBg.Position         = UDim2.new(0, 5, 0, 50)
	timerBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	timerBg.BorderSizePixel  = 0
	timerBg.Parent           = card

	local timerBar = Instance.new("Frame")
	timerBar.Size             = UDim2.new(1, 0, 1, 0)
	timerBar.BackgroundColor3 = rarityColor
	timerBar.BorderSizePixel  = 0
	timerBar.Parent           = timerBg

	-- Timer animieren
	TweenService:Create(timerBar,
		TweenInfo.new(data.timeLeft, Enum.EasingStyle.Linear),
		{ Size = UDim2.new(0, 0, 1, 0) }
	):Play()

	-- Fangen-Button
	local catchBtn = Instance.new("TextButton")
	catchBtn.Size              = UDim2.new(1, -10, 0, 22)
	catchBtn.Position          = UDim2.new(0, 5, 0, 62)
	catchBtn.BackgroundColor3  = rarityColor
	catchBtn.BorderSizePixel   = 0
	catchBtn.Font              = Enum.Font.GothamBold
	catchBtn.TextSize          = 13
	catchBtn.TextColor3        = Color3.fromRGB(0, 0, 0)
	catchBtn.Text              = "FANGEN"
	catchBtn.Parent            = card

	catchBtn.MouseButton1Click:Connect(function()
		catchBtn.Text    = "..."
		catchBtn.Active  = false
		catchRemote:FireServer(data.id)
	end)

	return card
end

-- Positionen aller Karten neu berechnen
local function reorderCards()
	local i = 0
	for _, card in pairs(cards) do
		i += 1
		card.Position = UDim2.new(1, -240, 0, 60 + (i - 1) * 100)
	end
end

-- Neuer Brainrot gespawnt
spawnedRemote.OnClientEvent:Connect(function(data)
	local index = 0
	for _ in pairs(cards) do index += 1 end
	index += 1

	local card = createCard(data, index)
	cards[data.id] = card

	-- Karte nach Ablauf automatisch entfernen
	task.delay(data.timeLeft, function()
		if cards[data.id] then
			cards[data.id]:Destroy()
			cards[data.id] = nil
			reorderCards()
		end
	end)
end)

-- Brainrot despawnt (gefangen oder abgelaufen)
despawnRemote.OnClientEvent:Connect(function(id)
	if cards[id] then
		cards[id]:Destroy()
		cards[id] = nil
		reorderCards()
	end
end)

-- Server-Antwort auf Fang-Versuch
catchRemote.OnClientEvent:Connect(function(success, result)
	local HUD = require(script.Parent.HUD)
	if success then
		HUD.notify("Gefangen: " .. result.name .. "!", Color3.fromRGB(100, 255, 100))
	else
		HUD.notify("Fehlgeschlagen: " .. tostring(result), Color3.fromRGB(255, 100, 100))
	end
end)

return BrainrotUI
