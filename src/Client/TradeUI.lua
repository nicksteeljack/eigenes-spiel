-- TradeUI.lua (StarterPlayerScripts)
-- Trade-Fenster: Angebot erstellen, bestaetigen, ablehnen.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes   = ReplicatedStorage:WaitForChild("Remotes")
local tradeRemote = remotes:WaitForChild("Trade")

local TradeUI = {}

local currentTradeId = nil
local localData      = { cash = 0, brainrots = {}, materials = {} }

local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "TradeUI"
screenGui.ResetOnSpawn   = false
screenGui.IgnoreGuiInset = true
screenGui.Parent         = playerGui

-- Eingehendes Trade-Popup
local incomingFrame = Instance.new("Frame")
incomingFrame.Size             = UDim2.new(0, 320, 0, 120)
incomingFrame.Position         = UDim2.new(0.5, -160, 0, 70)
incomingFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
incomingFrame.BorderSizePixel  = 0
incomingFrame.Visible          = false
incomingFrame.Parent           = screenGui
local ic = Instance.new("UICorner"); ic.CornerRadius = UDim.new(0,10); ic.Parent = incomingFrame

local incomingLabel = Instance.new("TextLabel")
incomingLabel.Size             = UDim2.new(1, -10, 0, 50)
incomingLabel.Position         = UDim2.new(0, 5, 0, 5)
incomingLabel.BackgroundTransparency = 1
incomingLabel.TextColor3       = Color3.fromRGB(220,220,220)
incomingLabel.Font             = Enum.Font.GothamBold
incomingLabel.TextSize         = 15
incomingLabel.TextWrapped      = true
incomingLabel.Text             = "Trade-Anfrage von ..."
incomingLabel.Parent           = incomingFrame

local acceptBtn = Instance.new("TextButton")
acceptBtn.Size             = UDim2.new(0.45, 0, 0, 35)
acceptBtn.Position         = UDim2.new(0.05, 0, 1, -42)
acceptBtn.BackgroundColor3 = Color3.fromRGB(50, 160, 50)
acceptBtn.BorderSizePixel  = 0
acceptBtn.Font             = Enum.Font.GothamBold
acceptBtn.TextSize         = 14
acceptBtn.TextColor3       = Color3.fromRGB(255,255,255)
acceptBtn.Text             = "Annehmen"
acceptBtn.Parent           = incomingFrame
local ac = Instance.new("UICorner"); ac.CornerRadius = UDim.new(0,6); ac.Parent = acceptBtn

local declineBtn = Instance.new("TextButton")
declineBtn.Size             = UDim2.new(0.45, 0, 0, 35)
declineBtn.Position         = UDim2.new(0.5, 0, 1, -42)
declineBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
declineBtn.BorderSizePixel  = 0
declineBtn.Font             = Enum.Font.GothamBold
declineBtn.TextSize         = 14
declineBtn.TextColor3       = Color3.fromRGB(255,255,255)
declineBtn.Text             = "Ablehnen"
declineBtn.Parent           = incomingFrame
local dc = Instance.new("UICorner"); dc.CornerRadius = UDim.new(0,6); dc.Parent = declineBtn

-- Trade-Hauptfenster
local window = Instance.new("Frame")
window.Size             = UDim2.new(0, 500, 0, 400)
window.Position         = UDim2.new(0.5, -250, 0.5, -200)
window.BackgroundColor3 = Color3.fromRGB(18, 20, 28)
window.BorderSizePixel  = 0
window.Visible          = false
window.Parent           = screenGui
local wc = Instance.new("UICorner"); wc.CornerRadius = UDim.new(0,12); wc.Parent = window

local windowTitle = Instance.new("TextLabel")
windowTitle.Size             = UDim2.new(1, 0, 0, 40)
windowTitle.BackgroundTransparency = 1
windowTitle.TextColor3       = Color3.fromRGB(255,255,255)
windowTitle.Font             = Enum.Font.GothamBold
windowTitle.TextSize         = 18
windowTitle.Text             = "Trade"
windowTitle.Parent           = window

-- Mein Angebot (links)
local myOfferLabel = Instance.new("TextLabel")
myOfferLabel.Size             = UDim2.new(0.5, -5, 0, 25)
myOfferLabel.Position         = UDim2.new(0, 10, 0, 45)
myOfferLabel.BackgroundTransparency = 1
myOfferLabel.TextColor3       = Color3.fromRGB(100, 200, 255)
myOfferLabel.Font             = Enum.Font.GothamBold
myOfferLabel.TextSize         = 13
myOfferLabel.TextXAlignment   = Enum.TextXAlignment.Left
myOfferLabel.Text             = "Mein Angebot"
myOfferLabel.Parent           = window

local myOfferBox = Instance.new("TextBox")
myOfferBox.Size             = UDim2.new(0.5, -15, 1, -170)
myOfferBox.Position         = UDim2.new(0, 10, 0, 72)
myOfferBox.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
myOfferBox.BorderSizePixel  = 0
myOfferBox.Font             = Enum.Font.Gotham
myOfferBox.TextSize         = 12
myOfferBox.TextColor3       = Color3.fromRGB(200,200,200)
myOfferBox.TextXAlignment   = Enum.TextXAlignment.Left
myOfferBox.TextYAlignment   = Enum.TextYAlignment.Top
myOfferBox.MultiLine        = true
myOfferBox.ClearTextOnFocus = false
myOfferBox.Text             = "$ 0"
myOfferBox.Parent           = window

-- Ihr Angebot (rechts)
local theirOfferLabel = Instance.new("TextLabel")
theirOfferLabel.Size             = UDim2.new(0.5, -5, 0, 25)
theirOfferLabel.Position         = UDim2.new(0.5, 5, 0, 45)
theirOfferLabel.BackgroundTransparency = 1
theirOfferLabel.TextColor3       = Color3.fromRGB(255, 180, 100)
theirOfferLabel.Font             = Enum.Font.GothamBold
theirOfferLabel.TextSize         = 13
theirOfferLabel.TextXAlignment   = Enum.TextXAlignment.Left
theirOfferLabel.Text             = "Ihr Angebot"
theirOfferLabel.Parent           = window

local theirOfferBox = Instance.new("TextLabel")
theirOfferBox.Size             = UDim2.new(0.5, -15, 1, -170)
theirOfferBox.Position         = UDim2.new(0.5, 5, 0, 72)
theirOfferBox.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
theirOfferBox.BorderSizePixel  = 0
theirOfferBox.Font             = Enum.Font.Gotham
theirOfferBox.TextSize         = 12
theirOfferBox.TextColor3       = Color3.fromRGB(200,200,200)
theirOfferBox.TextXAlignment   = Enum.TextXAlignment.Left
theirOfferBox.TextYAlignment   = Enum.TextYAlignment.Top
theirOfferBox.TextWrapped      = true
theirOfferBox.Text             = "Warten..."
theirOfferBox.Parent           = window

-- Buttons unten
local sendOfferBtn = Instance.new("TextButton")
sendOfferBtn.Size             = UDim2.new(0.3, 0, 0, 38)
sendOfferBtn.Position         = UDim2.new(0.05, 0, 1, -50)
sendOfferBtn.BackgroundColor3 = Color3.fromRGB(50, 130, 220)
sendOfferBtn.BorderSizePixel  = 0
sendOfferBtn.Font             = Enum.Font.GothamBold
sendOfferBtn.TextSize         = 13
sendOfferBtn.TextColor3       = Color3.fromRGB(255,255,255)
sendOfferBtn.Text             = "Angebot senden"
sendOfferBtn.Parent           = window
local sc = Instance.new("UICorner"); sc.CornerRadius = UDim.new(0,6); sc.Parent = sendOfferBtn

local confirmBtn = Instance.new("TextButton")
confirmBtn.Size             = UDim2.new(0.3, 0, 0, 38)
confirmBtn.Position         = UDim2.new(0.37, 0, 1, -50)
confirmBtn.BackgroundColor3 = Color3.fromRGB(50, 160, 50)
confirmBtn.BorderSizePixel  = 0
confirmBtn.Font             = Enum.Font.GothamBold
confirmBtn.TextSize         = 13
confirmBtn.TextColor3       = Color3.fromRGB(255,255,255)
confirmBtn.Text             = "✓ Bestaetigen"
confirmBtn.Parent           = window
local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0,6); cc.Parent = confirmBtn

local cancelBtn = Instance.new("TextButton")
cancelBtn.Size             = UDim2.new(0.25, 0, 0, 38)
cancelBtn.Position         = UDim2.new(0.7, 0, 1, -50)
cancelBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
cancelBtn.BorderSizePixel  = 0
cancelBtn.Font             = Enum.Font.GothamBold
cancelBtn.TextSize         = 13
cancelBtn.TextColor3       = Color3.fromRGB(255,255,255)
cancelBtn.Text             = "Abbrechen"
cancelBtn.Parent           = window
local xc2 = Instance.new("UICorner"); xc2.CornerRadius = UDim.new(0,6); xc2.Parent = cancelBtn

-- Angebot parsen: erwartet "$ 100" als Format
local function parseOffer(text)
	local cash = tonumber(text:match("%$%s*(%d+)")) or 0
	return { cash = cash, brainrotIndices = {}, materials = {} }
end

sendOfferBtn.MouseButton1Click:Connect(function()
	if not currentTradeId then return end
	local offer = parseOffer(myOfferBox.Text)
	tradeRemote:FireServer({ action = "Offer", tradeId = currentTradeId, offer = offer })
end)

confirmBtn.MouseButton1Click:Connect(function()
	if not currentTradeId then return end
	tradeRemote:FireServer({ action = "Confirm", tradeId = currentTradeId })
end)

cancelBtn.MouseButton1Click:Connect(function()
	if not currentTradeId then return end
	tradeRemote:FireServer({ action = "Cancel", tradeId = currentTradeId })
	window.Visible = false
	currentTradeId = nil
end)

acceptBtn.MouseButton1Click:Connect(function()
	if not currentTradeId then return end
	tradeRemote:FireServer({ action = "Accept", tradeId = currentTradeId })
	incomingFrame.Visible = false
	window.Visible        = true
end)

declineBtn.MouseButton1Click:Connect(function()
	if not currentTradeId then return end
	tradeRemote:FireServer({ action = "Decline", tradeId = currentTradeId })
	incomingFrame.Visible = false
	currentTradeId = nil
end)

-- Server-Events
tradeRemote.OnClientEvent:Connect(function(data)
	local HUD = require(script.Parent.HUD)
	local action = data.action

	if action == "Incoming" then
		currentTradeId        = data.tradeId
		incomingLabel.Text    = "Trade-Anfrage von " .. tostring(data.from)
		incomingFrame.Visible = true

	elseif action == "Accepted" then
		incomingFrame.Visible = false
		window.Visible        = true
		theirOfferBox.Text    = "Warten auf Angebot..."

	elseif action == "OfferUpdated" then
		local offerB = data.offerB
		if offerB then
			theirOfferBox.Text = "$ " .. (offerB.cash or 0)
		end

	elseif action == "Complete" then
		window.Visible = false
		currentTradeId = nil
		HUD.notify("Trade abgeschlossen!", Color3.fromRGB(100, 255, 100))

	elseif action == "Cancelled" then
		window.Visible        = false
		incomingFrame.Visible = false
		currentTradeId = nil
		HUD.notify("Trade abgebrochen: " .. tostring(data.reason), Color3.fromRGB(255, 150, 50))

	elseif action == "Error" then
		HUD.notify(tostring(data.msg), Color3.fromRGB(255, 100, 100))
	end
end)

function TradeUI.updateData(data)
	localData = data
end

return TradeUI
