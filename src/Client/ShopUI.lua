-- ShopUI.lua (StarterPlayerScripts)
-- Shop-Fenster: Werkzeuge, Waffen, Koeder kaufen.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config            = require(game.ReplicatedStorage.Shared.Config)

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes   = ReplicatedStorage:WaitForChild("Remotes")
local buyRemote = remotes:WaitForChild("BuyItem")

local ShopUI = {}

local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "ShopUI"
screenGui.ResetOnSpawn   = false
screenGui.IgnoreGuiInset = true
screenGui.Parent         = playerGui

-- Oeffnen-Button (rechts unten)
local openBtn = Instance.new("TextButton")
openBtn.Size             = UDim2.new(0, 120, 0, 45)
openBtn.Position         = UDim2.new(1, -135, 1, -65)
openBtn.BackgroundColor3 = Color3.fromRGB(200, 140, 0)
openBtn.BorderSizePixel  = 0
openBtn.Font             = Enum.Font.GothamBold
openBtn.TextSize         = 15
openBtn.TextColor3       = Color3.fromRGB(0, 0, 0)
openBtn.Text             = "🛒 SHOP"
openBtn.Parent           = screenGui
local c1 = Instance.new("UICorner"); c1.CornerRadius = UDim.new(0,8); c1.Parent = openBtn

-- Fenster
local window = Instance.new("Frame")
window.Size             = UDim2.new(0, 460, 0, 480)
window.Position         = UDim2.new(0.5, -230, 0.5, -240)
window.BackgroundColor3 = Color3.fromRGB(22, 18, 10)
window.BorderSizePixel  = 0
window.Visible          = false
window.Parent           = screenGui
local c2 = Instance.new("UICorner"); c2.CornerRadius = UDim.new(0,12); c2.Parent = window

local title = Instance.new("TextLabel")
title.Size             = UDim2.new(1, -50, 0, 40)
title.Position         = UDim2.new(0, 15, 0, 5)
title.BackgroundTransparency = 1
title.TextColor3       = Color3.fromRGB(255, 200, 50)
title.Font             = Enum.Font.GothamBold
title.TextSize         = 20
title.TextXAlignment   = Enum.TextXAlignment.Left
title.Text             = "🛒 Shop"
title.Parent           = window

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

local scroll = Instance.new("ScrollingFrame")
scroll.Size             = UDim2.new(1, -20, 1, -55)
scroll.Position         = UDim2.new(0, 10, 0, 50)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel  = 0
scroll.ScrollBarThickness = 6
scroll.Parent           = window

local listLayout = Instance.new("UIListLayout")
listLayout.Padding   = UDim.new(0, 6)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent    = scroll

-- Shop-Eintrag erstellen
local function makeShopItem(name, price, desc, layoutOrder, itemKey, itemType)
	local row = Instance.new("Frame")
	row.Size             = UDim2.new(1, 0, 0, 56)
	row.BackgroundColor3 = Color3.fromRGB(35, 28, 15)
	row.BorderSizePixel  = 0
	row.LayoutOrder      = layoutOrder
	row.Parent           = scroll
	local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(0,6); rc.Parent = row

	local nameL = Instance.new("TextLabel")
	nameL.Size             = UDim2.new(0.6, 0, 0.5, 0)
	nameL.Position         = UDim2.new(0, 10, 0, 4)
	nameL.BackgroundTransparency = 1
	nameL.TextColor3       = Color3.fromRGB(255, 220, 100)
	nameL.Font             = Enum.Font.GothamBold
	nameL.TextSize         = 14
	nameL.TextXAlignment   = Enum.TextXAlignment.Left
	nameL.Text             = name
	nameL.Parent           = row

	local descL = Instance.new("TextLabel")
	descL.Size             = UDim2.new(0.6, 0, 0.5, 0)
	descL.Position         = UDim2.new(0, 10, 0.5, 0)
	descL.BackgroundTransparency = 1
	descL.TextColor3       = Color3.fromRGB(150, 140, 120)
	descL.Font             = Enum.Font.Gotham
	descL.TextSize         = 11
	descL.TextXAlignment   = Enum.TextXAlignment.Left
	descL.Text             = desc
	descL.Parent           = row

	local buyBtn = Instance.new("TextButton")
	buyBtn.Size             = UDim2.new(0, 110, 0, 34)
	buyBtn.Position         = UDim2.new(1, -120, 0.5, -17)
	buyBtn.BackgroundColor3 = Color3.fromRGB(200, 140, 0)
	buyBtn.BorderSizePixel  = 0
	buyBtn.Font             = Enum.Font.GothamBold
	buyBtn.TextSize         = 13
	buyBtn.TextColor3       = Color3.fromRGB(0,0,0)
	buyBtn.Text             = "$ " .. price
	buyBtn.Parent           = row
	local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0,6); bc.Parent = buyBtn

	buyBtn.MouseButton1Click:Connect(function()
		buyRemote:FireServer({ itemKey = itemKey, itemType = itemType })
	end)
end

-- Shop-Eintraege befuellen
local function buildShop()
	local i = 0
	-- Werkzeuge
	for name, cfg in pairs(Config.Werkzeuge) do
		i += 1
		local desc = cfg.consumable and "Verbrauchsitem" or (cfg.breakAfter and ("Bricht nach " .. cfg.breakAfter .. " Verwendungen") or "Permanent")
		makeShopItem(name, cfg.price, desc, i, name, "Werkzeug")
	end
	-- Waffen
	for _, w in ipairs(Config.Waffen) do
		if w.priceCash > 0 then
			i += 1
			makeShopItem(w.name, w.priceCash, w.type .. " · " .. w.damage .. " Schaden", i, w.name, "Waffe")
		end
	end
	scroll.CanvasSize = UDim2.new(0, 0, 0, i * 62)
end

buildShop()

openBtn.MouseButton1Click:Connect(function()
	window.Visible = not window.Visible
end)
closeBtn.MouseButton1Click:Connect(function()
	window.Visible = false
end)

buyRemote.OnClientEvent:Connect(function(success, msg)
	local HUD = require(script.Parent.HUD)
	if success then
		HUD.notify("Gekauft!", Color3.fromRGB(255, 220, 50))
	else
		HUD.notify(tostring(msg), Color3.fromRGB(255, 100, 100))
	end
end)

return ShopUI
