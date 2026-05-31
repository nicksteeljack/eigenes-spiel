-- BaseUI.lua (StarterPlayerScripts)
-- Oeffnet die Spieler-Base: zeigt Brainrots, Einnahmen und Slot-Upgrade.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes   = ReplicatedStorage:WaitForChild("Remotes")
local upgradeRemote = remotes:WaitForChild("UpgradeBaseSlot")

local BaseUI = {}

-- Spieler-Daten lokal (werden vom Server aktualisiert)
local localData = { cash = 0, brainrots = {}, baseSlots = 10, rebirthLevel = 0 }

-- Haupt-GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "BaseUI"
screenGui.ResetOnSpawn   = false
screenGui.IgnoreGuiInset = true
screenGui.Parent         = playerGui

-- Oeffnen-Button links unten
local openBtn = Instance.new("TextButton")
openBtn.Size             = UDim2.new(0, 120, 0, 45)
openBtn.Position         = UDim2.new(0, 15, 1, -65)
openBtn.BackgroundColor3 = Color3.fromRGB(40, 100, 200)
openBtn.BorderSizePixel  = 0
openBtn.Font             = Enum.Font.GothamBold
openBtn.TextSize         = 15
openBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
openBtn.Text             = "🏠 BASE"
openBtn.Parent           = screenGui

local c1 = Instance.new("UICorner"); c1.CornerRadius = UDim.new(0,8); c1.Parent = openBtn

-- Haupt-Fenster (zentriert)
local window = Instance.new("Frame")
window.Size             = UDim2.new(0, 500, 0, 420)
window.Position         = UDim2.new(0.5, -250, 0.5, -210)
window.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
window.BorderSizePixel  = 0
window.Visible          = false
window.Parent           = screenGui

local c2 = Instance.new("UICorner"); c2.CornerRadius = UDim.new(0,12); c2.Parent = window

-- Titel
local title = Instance.new("TextLabel")
title.Size             = UDim2.new(1, -50, 0, 40)
title.Position         = UDim2.new(0, 15, 0, 5)
title.BackgroundTransparency = 1
title.TextColor3       = Color3.fromRGB(255, 255, 255)
title.Font             = Enum.Font.GothamBold
title.TextSize         = 20
title.TextXAlignment   = Enum.TextXAlignment.Left
title.Text             = "Meine Base"
title.Parent           = window

-- Schliessen-Button
local closeBtn = Instance.new("TextButton")
closeBtn.Size             = UDim2.new(0, 35, 0, 35)
closeBtn.Position         = UDim2.new(1, -40, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
closeBtn.BorderSizePixel  = 0
closeBtn.Font             = Enum.Font.GothamBold
closeBtn.TextSize         = 18
closeBtn.TextColor3       = Color3.fromRGB(255,255,255)
closeBtn.Text             = "✕"
closeBtn.Parent           = window
local c3 = Instance.new("UICorner"); c3.CornerRadius = UDim.new(0,6); c3.Parent = closeBtn

-- Info-Leiste (Slots, Einnahmen)
local infoBar = Instance.new("TextLabel")
infoBar.Size             = UDim2.new(1, -20, 0, 28)
infoBar.Position         = UDim2.new(0, 10, 0, 48)
infoBar.BackgroundTransparency = 1
infoBar.TextColor3       = Color3.fromRGB(180, 180, 180)
infoBar.Font             = Enum.Font.Gotham
infoBar.TextSize         = 13
infoBar.TextXAlignment   = Enum.TextXAlignment.Left
infoBar.Text             = "Slots: 0/10  ·  Einnahmen: 0$/h"
infoBar.Parent           = window

-- Slot-Upgrade-Button
local upgradeBtn = Instance.new("TextButton")
upgradeBtn.Size             = UDim2.new(0, 160, 0, 30)
upgradeBtn.Position         = UDim2.new(1, -170, 0, 48)
upgradeBtn.BackgroundColor3 = Color3.fromRGB(255, 180, 0)
upgradeBtn.BorderSizePixel  = 0
upgradeBtn.Font             = Enum.Font.GothamBold
upgradeBtn.TextSize         = 13
upgradeBtn.TextColor3       = Color3.fromRGB(0, 0, 0)
upgradeBtn.Text             = "Slot upgraden"
upgradeBtn.Parent           = window
local c4 = Instance.new("UICorner"); c4.CornerRadius = UDim.new(0,6); c4.Parent = upgradeBtn

-- Scroll-Liste fuer Brainrots
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size             = UDim2.new(1, -20, 1, -90)
scrollFrame.Position         = UDim2.new(0, 10, 0, 85)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel  = 0
scrollFrame.ScrollBarThickness = 6
scrollFrame.Parent           = window

local listLayout = Instance.new("UIListLayout")
listLayout.Padding           = UDim.new(0, 6)
listLayout.SortOrder         = Enum.SortOrder.LayoutOrder
listLayout.Parent            = scrollFrame

local RARITY_COLORS = {
	Common          = Color3.fromRGB(200, 200, 200),
	Rare            = Color3.fromRGB(100, 150, 255),
	["Secret Rare"] = Color3.fromRGB(255, 100, 220),
	OG              = Color3.fromRGB(255, 215, 0),
}

-- Brainrot-Eintrag in der Liste erstellen
local function makeBrainrotEntry(br, index)
	local row = Instance.new("Frame")
	row.Size             = UDim2.new(1, 0, 0, 52)
	row.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
	row.BorderSizePixel  = 0
	row.LayoutOrder      = index
	row.Parent           = scrollFrame

	local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(0,6); rc.Parent = row

	local color = RARITY_COLORS[br.rarity] or Color3.fromRGB(255,255,255)

	local stripe = Instance.new("Frame")
	stripe.Size             = UDim2.new(0, 4, 1, 0)
	stripe.BackgroundColor3 = color
	stripe.BorderSizePixel  = 0
	stripe.Parent           = row

	local nameL = Instance.new("TextLabel")
	nameL.Size             = UDim2.new(0.6, 0, 0, 24)
	nameL.Position         = UDim2.new(0, 12, 0, 4)
	nameL.BackgroundTransparency = 1
	nameL.TextColor3       = color
	nameL.Font             = Enum.Font.GothamBold
	nameL.TextSize         = 14
	nameL.TextXAlignment   = Enum.TextXAlignment.Left
	nameL.TextTruncate     = Enum.TextTruncate.AtEnd
	nameL.Text             = br.name
	nameL.Parent           = row

	local infoL = Instance.new("TextLabel")
	infoL.Size             = UDim2.new(0.6, 0, 0, 20)
	infoL.Position         = UDim2.new(0, 12, 0, 28)
	infoL.BackgroundTransparency = 1
	infoL.TextColor3       = Color3.fromRGB(150, 150, 150)
	infoL.Font             = Enum.Font.Gotham
	infoL.TextSize         = 12
	infoL.TextXAlignment   = Enum.TextXAlignment.Left
	infoL.Text             = br.rarity .. "  ·  " .. br.mutation
		.. (br.traits and #br.traits > 0 and ("  ·  " .. table.concat(br.traits, ", ")) or "")
	infoL.Parent           = row
end

-- Fenster neu aufbauen
local function refresh()
	-- Alte Eintraege loeschen
	for _, child in ipairs(scrollFrame:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	local brainrots  = localData.brainrots or {}
	local slots      = localData.baseSlots or 10
	local totalDPH   = 0

	for i, br in ipairs(brainrots) do
		makeBrainrotEntry(br, i)
		-- Einnahmen schaetzen (Client-seitig ohne Config-Zugriff: nur anzeigen)
	end

	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, #brainrots * 58)
	infoBar.Text = "Slots: " .. #brainrots .. "/" .. slots .. "  ·  Einnahmen werden vom Server berechnet"
end

-- Fenster oeffnen/schliessen
openBtn.MouseButton1Click:Connect(function()
	window.Visible = not window.Visible
	if window.Visible then refresh() end
end)
closeBtn.MouseButton1Click:Connect(function()
	window.Visible = false
end)

-- Slot-Upgrade
upgradeBtn.MouseButton1Click:Connect(function()
	upgradeRemote:FireServer()
end)

upgradeRemote.OnClientEvent:Connect(function(success, result)
	local HUD = require(script.Parent.HUD)
	if success then
		localData.baseSlots = result
		HUD.notify("Slot freigeschaltet! (" .. result .. " Slots)", Color3.fromRGB(255, 220, 50))
		if window.Visible then refresh() end
	else
		HUD.notify(tostring(result), Color3.fromRGB(255, 100, 100))
	end
end)

-- Daten von aussen aktualisieren (wird von Main.client aufgerufen)
function BaseUI.updateData(data)
	localData = data
	if window.Visible then refresh() end
end

return BaseUI
