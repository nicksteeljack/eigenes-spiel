-- CollectUI.lua (StarterPlayerScripts)
-- Zeigt Sammel-Buttons je nach Zone (Pilze, Fischen, Muscheln).

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes   = ReplicatedStorage:WaitForChild("Remotes")
local collectRemote = remotes:WaitForChild("Collect")

local CollectUI = {}

local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "CollectUI"
screenGui.ResetOnSpawn   = false
screenGui.IgnoreGuiInset = true
screenGui.Parent         = playerGui

-- Sammel-Button unten in der Mitte
local collectBtn = Instance.new("TextButton")
collectBtn.Size             = UDim2.new(0, 200, 0, 55)
collectBtn.Position         = UDim2.new(0.5, -100, 1, -80)
collectBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 60)
collectBtn.BorderSizePixel  = 0
collectBtn.Font             = Enum.Font.GothamBold
collectBtn.TextSize         = 18
collectBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
collectBtn.Text             = "SAMMELN"
collectBtn.Visible          = false
collectBtn.Parent           = screenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent       = collectBtn

-- Aktueller Sammel-Typ je nach Zone
local currentType = nil

local zoneToType = {
	Wald   = "Pilz",
	Wasser = "Fisch",
	Strand = "Muschel",
}

local zoneToLabel = {
	Pilz   = "🍄 PILZE SAMMELN",
	Fisch  = "🎣 ANGELN",
	Muschel= "🐚 MUSCHELN GRABEN",
}

local zoneToColor = {
	Pilz   = Color3.fromRGB(60, 180, 60),
	Fisch  = Color3.fromRGB(50, 130, 220),
	Muschel= Color3.fromRGB(200, 150, 50),
}

-- Zone wechselt: Button anpassen
function CollectUI.setZone(zoneName)
	currentType = zoneToType[zoneName]
	if currentType then
		collectBtn.Text             = zoneToLabel[currentType] or "SAMMELN"
		collectBtn.BackgroundColor3 = zoneToColor[currentType] or Color3.fromRGB(60,180,60)
		collectBtn.Visible          = true
	else
		collectBtn.Visible = false
	end
end

-- Cooldown-Sperre nach Klick
local onCooldown = false

collectBtn.MouseButton1Click:Connect(function()
	if onCooldown or not currentType then return end
	onCooldown = true
	collectBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)

	collectRemote:FireServer({ type = currentType })

	task.wait(0.5)
	onCooldown = false
	if currentType then
		collectBtn.BackgroundColor3 = zoneToColor[currentType] or Color3.fromRGB(60,180,60)
	end
end)

-- Server-Antwort
collectRemote.OnClientEvent:Connect(function(result)
	local HUD = require(script.Parent.HUD)
	if result.success then
		local item = result.item
		HUD.notify("+" .. item.name, Color3.fromRGB(100, 255, 150))
	else
		HUD.notify(result.msg or "Fehler", Color3.fromRGB(255, 100, 100))
	end
end)

return CollectUI
