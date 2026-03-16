--[[
	Obby Client — Main.client.luau
	Single client script (Single-Script Architecture).

	HUD elements:
	  - Checkpoint counter (stage X / N)
	  - Coin counter
	  - Timer (elapsed since first checkpoint)
	  - Death counter
	  - Shop button (skip stage / VIP)
	  - Cross-promo banner (after world 1 completion)
]]

local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--------------------------------------------------------------------------------
-- Wait for remotes
--------------------------------------------------------------------------------
local function waitRemote(key: string): RemoteEvent
	return ReplicatedStorage:WaitForChild(Config.REMOTES[key]) :: RemoteEvent
end

local CheckpointReached = waitRemote("CheckpointReached")
local CoinCollected     = waitRemote("CoinCollected")
local TimerSync         = waitRemote("TimerSync")
local PlayerDied        = waitRemote("PlayerDied")
local CrossPromo        = waitRemote("CrossPromo")
local RequestSkip       = waitRemote("RequestSkip")
local StatsSync         = waitRemote("StatsSync")
local PurchaseResult    = waitRemote("PurchaseResult")

--------------------------------------------------------------------------------
-- State
--------------------------------------------------------------------------------
local currentCheckpoint = 0
local totalCoins        = 0
local deaths            = 0
local elapsed           = 0
local courseComplete     = false

--------------------------------------------------------------------------------
-- HUD
--------------------------------------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ObbyHUD"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Helper: create a rounded dark panel
local function makePanel(size: UDim2, position: UDim2, parent: Instance): Frame
	local frame = Instance.new("Frame")
	frame.Size = size
	frame.Position = position
	frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	frame.BackgroundTransparency = 0.35
	frame.BorderSizePixel = 0
	frame.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = frame

	return frame
end

-- Helper: create a text label inside a frame
local function makeLabel(parent: Frame, text: string): TextLabel
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -12, 1, 0)
	label.Position = UDim2.new(0, 6, 0, 0)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = text
	label.Parent = parent
	return label
end

-- Top-left: Stats panel
local statsPanel = makePanel(UDim2.new(0, 240, 0, 140), UDim2.new(0, 16, 0, 16), screenGui)

local checkpointLabel = makeLabel(
	makePanel(UDim2.new(1, -16, 0, 28), UDim2.new(0, 8, 0, 8), statsPanel),
	"Stage: 0 / " .. Config.TOTAL_STAGES
)

local coinLabel = makeLabel(
	makePanel(UDim2.new(1, -16, 0, 28), UDim2.new(0, 8, 0, 40), statsPanel),
	"Coins: 0"
)

local timerLabel = makeLabel(
	makePanel(UDim2.new(1, -16, 0, 28), UDim2.new(0, 8, 0, 72), statsPanel),
	"Time: 0:00"
)

local deathLabel = makeLabel(
	makePanel(UDim2.new(1, -16, 0, 28), UDim2.new(0, 8, 0, 104), statsPanel),
	"Deaths: 0"
)

-- Top-right: Shop button
local shopBtn = Instance.new("TextButton")
shopBtn.Size = UDim2.new(0, 120, 0, 40)
shopBtn.Position = UDim2.new(1, -136, 0, 16)
shopBtn.BackgroundColor3 = Color3.fromRGB(50, 120, 220)
shopBtn.BorderSizePixel = 0
shopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
shopBtn.TextScaled = true
shopBtn.Font = Enum.Font.GothamBold
shopBtn.Text = "Shop"
shopBtn.Parent = screenGui

local shopCorner = Instance.new("UICorner")
shopCorner.CornerRadius = UDim.new(0, 10)
shopCorner.Parent = shopBtn

-- Shop panel (hidden by default)
local shopPanel = makePanel(UDim2.new(0, 260, 0, 160), UDim2.new(1, -276, 0, 64), screenGui)
shopPanel.Visible = false

local skipBtn = Instance.new("TextButton")
skipBtn.Size = UDim2.new(1, -16, 0, 44)
skipBtn.Position = UDim2.new(0, 8, 0, 12)
skipBtn.BackgroundColor3 = Color3.fromRGB(80, 180, 80)
skipBtn.BorderSizePixel = 0
skipBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
skipBtn.TextScaled = true
skipBtn.Font = Enum.Font.GothamBold
skipBtn.Text = "Skip Stage (" .. Config.SKIP_STAGE_PRICE_ROBUX .. " R$)"
skipBtn.Parent = shopPanel

local skipCorner = Instance.new("UICorner")
skipCorner.CornerRadius = UDim.new(0, 8)
skipCorner.Parent = skipBtn

local vipBtn = Instance.new("TextButton")
vipBtn.Size = UDim2.new(1, -16, 0, 44)
vipBtn.Position = UDim2.new(0, 8, 0, 64)
vipBtn.BackgroundColor3 = Color3.fromRGB(255, 180, 30)
vipBtn.BorderSizePixel = 0
vipBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
vipBtn.TextScaled = true
vipBtn.Font = Enum.Font.GothamBold
vipBtn.Text = "VIP Pass (" .. Config.VIP_PASS_PRICE_ROBUX .. " R$)"
vipBtn.Parent = shopPanel

local vipCorner = Instance.new("UICorner")
vipCorner.CornerRadius = UDim.new(0, 8)
vipCorner.Parent = vipBtn

local closeShopBtn = Instance.new("TextButton")
closeShopBtn.Size = UDim2.new(1, -16, 0, 30)
closeShopBtn.Position = UDim2.new(0, 8, 0, 118)
closeShopBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
closeShopBtn.BorderSizePixel = 0
closeShopBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
closeShopBtn.TextScaled = true
closeShopBtn.Font = Enum.Font.Gotham
closeShopBtn.Text = "Close"
closeShopBtn.Parent = shopPanel

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeShopBtn

-- Cross-promo banner (hidden until world 1 complete)
local promoBanner = makePanel(UDim2.new(0, 400, 0, 80), UDim2.new(0.5, -200, 0.5, -40), screenGui)
promoBanner.Visible = false
promoBanner.BackgroundColor3 = Color3.fromRGB(60, 20, 100)
promoBanner.BackgroundTransparency = 0.15

local promoLabel = makeLabel(promoBanner, Config.CROSS_PROMO_MESSAGE)
promoLabel.TextXAlignment = Enum.TextXAlignment.Center

local promoPlayBtn = Instance.new("TextButton")
promoPlayBtn.Size = UDim2.new(0, 120, 0, 30)
promoPlayBtn.Position = UDim2.new(0.5, -60, 1, 8)
promoPlayBtn.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
promoPlayBtn.BorderSizePixel = 0
promoPlayBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
promoPlayBtn.TextScaled = true
promoPlayBtn.Font = Enum.Font.GothamBold
promoPlayBtn.Text = "Play Now!"
promoPlayBtn.Parent = promoBanner

local promoCorner = Instance.new("UICorner")
promoCorner.CornerRadius = UDim.new(0, 8)
promoCorner.Parent = promoPlayBtn

local promoDismissBtn = Instance.new("TextButton")
promoDismissBtn.Size = UDim2.new(0, 24, 0, 24)
promoDismissBtn.Position = UDim2.new(1, -28, 0, 4)
promoDismissBtn.BackgroundTransparency = 1
promoDismissBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
promoDismissBtn.TextScaled = true
promoDismissBtn.Font = Enum.Font.GothamBold
promoDismissBtn.Text = "X"
promoDismissBtn.Parent = promoBanner

--------------------------------------------------------------------------------
-- UI interactions
--------------------------------------------------------------------------------
shopBtn.Activated:Connect(function()
	shopPanel.Visible = not shopPanel.Visible
end)

closeShopBtn.Activated:Connect(function()
	shopPanel.Visible = false
end)

skipBtn.Activated:Connect(function()
	if courseComplete then return end
	if Config.SKIP_STAGE_PRODUCT_ID > 0 then
		MarketplaceService:PromptProductPurchase(player, Config.SKIP_STAGE_PRODUCT_ID)
	else
		-- Placeholder: fire skip request directly for testing
		RequestSkip:FireServer()
	end
	shopPanel.Visible = false
end)

vipBtn.Activated:Connect(function()
	if Config.VIP_GAME_PASS_ID > 0 then
		MarketplaceService:PromptGamePassPurchase(player, Config.VIP_GAME_PASS_ID)
	end
	shopPanel.Visible = false
end)

promoPlayBtn.Activated:Connect(function()
	if Config.ALCHEMY_ACADEMY_PLACE_ID > 0 then
		local TeleportService = game:GetService("TeleportService")
		TeleportService:Teleport(Config.ALCHEMY_ACADEMY_PLACE_ID, player)
	end
end)

promoDismissBtn.Activated:Connect(function()
	promoBanner.Visible = false
end)

--------------------------------------------------------------------------------
-- Remote event handlers
--------------------------------------------------------------------------------
CheckpointReached.OnClientEvent:Connect(function(num: number)
	currentCheckpoint = num
	if num >= Config.TOTAL_STAGES then
		checkpointLabel.Text = "Course Complete!"
		checkpointLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
		courseComplete = true
	else
		checkpointLabel.Text = "Stage: " .. num .. " / " .. Config.TOTAL_STAGES
		checkpointLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	end
end)

CoinCollected.OnClientEvent:Connect(function(newTotal: number)
	totalCoins = newTotal
	coinLabel.Text = "Coins: " .. newTotal
end)

TimerSync.OnClientEvent:Connect(function(seconds: number)
	elapsed = seconds
	local mins = math.floor(seconds / 60)
	local secs = seconds % 60
	timerLabel.Text = string.format("Time: %d:%02d", mins, secs)
end)

PlayerDied.OnClientEvent:Connect(function(deathCount: number)
	deaths = deathCount
	deathLabel.Text = "Deaths: " .. deathCount
end)

CrossPromo.OnClientEvent:Connect(function()
	promoBanner.Visible = true
end)

StatsSync.OnClientEvent:Connect(function(stats: { checkpoint: number, coins: number, deaths: number, elapsed: number })
	currentCheckpoint = stats.checkpoint or 0
	totalCoins = stats.coins or 0
	deaths = stats.deaths or 0
	elapsed = stats.elapsed or 0

	checkpointLabel.Text = "Stage: " .. currentCheckpoint .. " / " .. Config.TOTAL_STAGES
	coinLabel.Text = "Coins: " .. totalCoins
	deathLabel.Text = "Deaths: " .. deaths
	local mins = math.floor(elapsed / 60)
	local secs = elapsed % 60
	timerLabel.Text = string.format("Time: %d:%02d", mins, secs)
end)

PurchaseResult.OnClientEvent:Connect(function(success: boolean, message: string)
	-- Brief feedback toast
	local toast = makePanel(UDim2.new(0, 300, 0, 40), UDim2.new(0.5, -150, 1, -60), screenGui)
	toast.BackgroundColor3 = success and Color3.fromRGB(40, 140, 40) or Color3.fromRGB(180, 40, 40)
	local toastLabel = makeLabel(toast, message)
	toastLabel.TextXAlignment = Enum.TextXAlignment.Center
	task.delay(3, function()
		if toast and toast.Parent then
			toast:Destroy()
		end
	end)
end)
