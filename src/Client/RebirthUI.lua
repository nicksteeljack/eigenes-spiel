-- RebirthUI.lua (StarterPlayerScripts)
-- Rebirth-Fenster: Materialien auswaehlen und einloesen.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config            = require(game.ReplicatedStorage.Shared.Config)

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes   = ReplicatedStorage:WaitForChild("Remotes")
local rebirthRemote = remotes:WaitForChild("Rebirth")

local RebirthUI = {}

local localMaterials = {}
local localLevel     = 0

local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "RebirthUI"
screenGui.ResetOnSpawn   = false
screenGui.IgnoreGuiInset = true
screenGui.Parent         = playerGui

-- Oeffnen-Button links (ueber Base-Button)
local openBtn = Instance.new("TextButton")
openBtn.Size             = UDim2.new(0, 120, 0, 45)
openBtn.Position         = UDim2.new(0, 15, 1, -115)
openBtn.BackgroundColor3 = Color3.fromRGB(140, 60, 200)
openBtn.BorderSizePixel  = 0
openBtn.Font             = Enum.Font.GothamBold
openBtn.TextSize         = 15
openBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
openBtn.Text             = "⬆ REBIRTH"
openBtn.Parent           = screenGui
local c1 = Instance.new("UICorner"); c1.CornerRadius = UDim.new(0,8); c1.Parent = openBtn

-- Fenster
local window = Instance.new("Frame")
window.Size             = UDim2.new(0, 480, 0, 500)
window.Position         = UDim2.new(0.5, -240, 0.5, -250)
window.BackgroundColor3 = Color3.fromRGB(20, 15, 30)
window.BorderSizePixel  = 0
window.Visible          = false
window.Parent           = screenGui
local c2 = Instance.new("UICorner"); c2.CornerRadius = UDim.new(0,12); c2.Parent = window

-- Titel
local title = Instance.new("TextLabel")
title.Size             = UDim2.new(1, -50, 0, 40)
title.Position         = UDim2.new(0, 15, 0, 5)
title.BackgroundTransparency = 1
title.TextColor3       = Color3.fromRGB(200, 100, 255)
title.Font             = Enum.Font.GothamBold
title.TextSize         = 20
title.TextXAlignment   = Enum.TextXAlignment.Left
title.Text             = "⬆ Rebirth"
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

-- Aktuelle Stufe + Fortschritt
local levelLabel = Instance.new("TextLabel")
levelLabel.Size             = UDim2.new(1, -20, 0, 30)
levelLabel.Position         = UDim2.new(0, 10, 0, 48)
levelLabel.BackgroundTransparency = 1
levelLabel.TextColor3       = Color3.fromRGB(220, 220, 220)
levelLabel.Font             = Enum.Font.GothamBold
levelLabel.TextSize         = 15
levelLabel.TextXAlignment   = Enum.TextXAlignment.Left
levelLabel.Text             = "Stufe 0 → 1  ·  Benoetigt: 50 Punkte"
levelLabel.Parent           = window

-- Punkte-Anzeige
local pointsLabel = Instance.new("TextLabel")
pointsLabel.Size             = UDim2.new(1, -20, 0, 22)
pointsLabel.Position         = UDim2.new(0, 10, 0, 78)
pointsLabel.BackgroundTransparency = 1
pointsLabel.TextColor3       = Color3.fromRGB(160, 160, 160)
pointsLabel.Font             = Enum.Font.Gotham
pointsLabel.TextSize         = 13
pointsLabel.TextXAlignment   = Enum.TextXAlignment.Left
pointsLabel.Text             = "Ausgewaehlte Punkte: 0"
pointsLabel.Parent           = window

-- Scroll-Liste fuer Materialien
local scroll = Instance.new("ScrollingFrame")
scroll.Size             = UDim2.new(1, -20, 1, -175)
scroll.Position         = UDim2.new(0, 10, 0, 105)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel  = 0
scroll.ScrollBarThickness = 6
scroll.Parent           = window

local listLayout = Instance.new("UIListLayout")
listLayout.Padding   = UDim.new(0, 4)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent    = scroll

-- Rebirth-Button unten
local rebirthBtn = Instance.new("TextButton")
rebirthBtn.Size             = UDim2.new(1, -20, 0, 45)
rebirthBtn.Position         = UDim2.new(0, 10, 1, -55)
rebirthBtn.BackgroundColor3 = Color3.fromRGB(140, 60, 200)
rebirthBtn.BorderSizePixel  = 0
rebirthBtn.Font             = Enum.Font.GothamBold
rebirthBtn.TextSize         = 16
rebirthBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
rebirthBtn.Text             = "REBIRTH DURCHFUEHREN"
rebirthBtn.Parent           = window
local c4 = Instance.new("UICorner"); c4.CornerRadius = UDim.new(0,8); c4.Parent = rebirthBtn

-- Ausgewaehlte Mengen: [materialName] = menge
local selected = {}

-- Punkt-Wert eines Materials suchen
local function getPoints(name)
	for _, tbl in ipairs({ Config.Pilze, Config.Fische, Config.Muscheln }) do
		for _, e in ipairs(tbl) do
			if e.name == name then return e.rebirthPoints end
		end
	end
	return 0
end

local function totalSelectedPoints()
	local total = 0
	for name, amt in pairs(selected) do
		total += getPoints(name) * amt
	end
	return total
end

local function refreshPoints()
	pointsLabel.Text = "Ausgewaehlte Punkte: " .. totalSelectedPoints()
end

-- Material-Zeile erstellen
local function makeMaterialRow(name, available, pts, index)
	local row = Instance.new("Frame")
	row.Size             = UDim2.new(1, 0, 0, 44)
	row.BackgroundColor3 = Color3.fromRGB(35, 28, 50)
	row.BorderSizePixel  = 0
	row.LayoutOrder      = index
	row.Parent           = scroll
	local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(0,6); rc.Parent = row

	local nameL = Instance.new("TextLabel")
	nameL.Size             = UDim2.new(0.4, 0, 0.5, 0)
	nameL.Position         = UDim2.new(0, 10, 0, 4)
	nameL.BackgroundTransparency = 1
	nameL.TextColor3       = Color3.fromRGB(220, 220, 220)
	nameL.Font             = Enum.Font.GothamBold
	nameL.TextSize         = 13
	nameL.TextXAlignment   = Enum.TextXAlignment.Left
	nameL.Text             = name
	nameL.Parent           = row

	local availL = Instance.new("TextLabel")
	availL.Size             = UDim2.new(0.25, 0, 0.5, 0)
	availL.Position         = UDim2.new(0, 10, 0.5, 0)
	availL.BackgroundTransparency = 1
	availL.TextColor3       = Color3.fromRGB(140, 140, 140)
	availL.Font             = Enum.Font.Gotham
	availL.TextSize         = 11
	availL.TextXAlignment   = Enum.TextXAlignment.Left
	availL.Text             = "Vorhanden: " .. available .. "  (" .. pts .. "P/Stk)"
	availL.Parent           = row

	-- Minus / Anzahl / Plus
	local minus = Instance.new("TextButton")
	minus.Size             = UDim2.new(0, 28, 0, 28)
	minus.Position         = UDim2.new(0.65, 0, 0.5, -14)
	minus.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
	minus.BorderSizePixel  = 0
	minus.Font             = Enum.Font.GothamBold
	minus.TextSize         = 16
	minus.TextColor3       = Color3.fromRGB(255,255,255)
	minus.Text             = "-"
	minus.Parent           = row
	local mc = Instance.new("UICorner"); mc.CornerRadius = UDim.new(0,4); mc.Parent = minus

	local amountL = Instance.new("TextLabel")
	amountL.Size             = UDim2.new(0, 40, 0, 28)
	amountL.Position         = UDim2.new(0.65, 32, 0.5, -14)
	amountL.BackgroundTransparency = 1
	amountL.TextColor3       = Color3.fromRGB(255,255,255)
	amountL.Font             = Enum.Font.GothamBold
	amountL.TextSize         = 14
	amountL.Text             = "0"
	amountL.Parent           = row

	local plus = Instance.new("TextButton")
	plus.Size             = UDim2.new(0, 28, 0, 28)
	plus.Position         = UDim2.new(0.65, 76, 0.5, -14)
	plus.BackgroundColor3 = Color3.fromRGB(50, 160, 50)
	plus.BorderSizePixel  = 0
	plus.Font             = Enum.Font.GothamBold
	plus.TextSize         = 16
	plus.TextColor3       = Color3.fromRGB(255,255,255)
	plus.Text             = "+"
	plus.Parent           = row
	local pc = Instance.new("UICorner"); pc.CornerRadius = UDim.new(0,4); pc.Parent = plus

	-- Max-Button
	local maxBtn = Instance.new("TextButton")
	maxBtn.Size             = UDim2.new(0, 36, 0, 28)
	maxBtn.Position         = UDim2.new(0.65, 108, 0.5, -14)
	maxBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
	maxBtn.BorderSizePixel  = 0
	maxBtn.Font             = Enum.Font.GothamBold
	maxBtn.TextSize         = 11
	maxBtn.TextColor3       = Color3.fromRGB(255,255,255)
	maxBtn.Text             = "MAX"
	maxBtn.Parent           = row
	local xc = Instance.new("UICorner"); xc.CornerRadius = UDim.new(0,4); xc.Parent = maxBtn

	selected[name] = selected[name] or 0

	local function updateAmount()
		amountL.Text = tostring(selected[name])
		refreshPoints()
	end

	minus.MouseButton1Click:Connect(function()
		selected[name] = math.max(0, (selected[name] or 0) - 1)
		updateAmount()
	end)
	plus.MouseButton1Click:Connect(function()
		selected[name] = math.min(available, (selected[name] or 0) + 1)
		updateAmount()
	end)
	maxBtn.MouseButton1Click:Connect(function()
		selected[name] = available
		updateAmount()
	end)
end

-- Fenster neu aufbauen
local function refresh()
	for _, c in ipairs(scroll:GetChildren()) do
		if c:IsA("Frame") then c:Destroy() end
	end
	selected = {}

	local nextLevelData = Config.Rebirth.levels[localLevel + 1]
	if nextLevelData then
		levelLabel.Text = "Stufe " .. localLevel .. " → " .. nextLevelData.level
			.. "  ·  Benoetigt: " .. nextLevelData.points .. " Punkte"
	else
		levelLabel.Text = "Maximale Stufe erreicht!"
		rebirthBtn.Active = false
	end

	local i = 0
	for matName, amount in pairs(localMaterials) do
		if amount > 0 then
			i += 1
			local pts = getPoints(matName)
			makeMaterialRow(matName, amount, pts, i)
		end
	end

	scroll.CanvasSize = UDim2.new(0, 0, 0, i * 48)
	refreshPoints()
end

openBtn.MouseButton1Click:Connect(function()
	window.Visible = not window.Visible
	if window.Visible then refresh() end
end)
closeBtn.MouseButton1Click:Connect(function()
	window.Visible = false
end)

rebirthBtn.MouseButton1Click:Connect(function()
	local toSpend = {}
	for name, amt in pairs(selected) do
		if amt > 0 then toSpend[name] = amt end
	end
	if next(toSpend) == nil then return end
	rebirthRemote:FireServer({ materialsToSpend = toSpend })
end)

rebirthRemote.OnClientEvent:Connect(function(result)
	local HUD = require(script.Parent.HUD)
	if result.success then
		localLevel = result.newLevel
		HUD.setRebirth(result.newLevel, result.multiplier)
		HUD.notify("Rebirth " .. result.newLevel .. "! Multiplikator: " .. result.multiplier .. "x", Color3.fromRGB(200, 100, 255))
		window.Visible = false
	else
		HUD.notify(result.msg or "Fehler", Color3.fromRGB(255, 100, 100))
	end
end)

function RebirthUI.updateData(data)
	localMaterials = data.materials or {}
	localLevel     = data.rebirthLevel or 0
	if window.Visible then refresh() end
end

return RebirthUI
