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
local RunService         = game:GetService("RunService")

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
local timerRunning      = false
local timerStart        = 0
local courseComplete     = false
local isVIP             = false

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

local function formatTime(seconds: number): string
	local mins = math.floor(seconds / 60)
	local secs = seconds - (mins * 60)
	return string.format("%d:%05.2f", mins, secs)
end

-- Top-left: Stats panel
local statsPanel = makePanel(UDim2.new(0, 240, 0, 172), UDim2.new(0, 16, 0, 16), screenGui)

local checkpointLabel = makeLabel(
	makePanel(UDim2.new(1, -16, 0, 28), UDim2.new(0, 8, 0, 8), statsPanel),
	"Stage: 0 / " .. Config.TOTAL_STAGES
)

local coinLabel = makeLabel(
	makePanel(UDim2.new(1, -16, 0, 28), UDim2.new(0, 8, 0, 40), statsPanel),
	"Coins: 0"
)
coinLabel.TextColor3 = Color3.fromRGB(255, 200, 50)

local timerLabel = makeLabel(
	makePanel(UDim2.new(1, -16, 0, 28), UDim2.new(0, 8, 0, 72), statsPanel),
	"Time: 0:00.00"
)

local deathLabel = makeLabel(
	makePanel(UDim2.new(1, -16, 0, 28), UDim2.new(0, 8, 0, 104), statsPanel),
	"Deaths: 0"
)
deathLabel.TextColor3 = Color3.fromRGB(255, 85, 85)

-- VIP badge (only visible when VIP)
local vipPanel = makePanel(UDim2.new(1, -16, 0, 24), UDim2.new(0, 8, 0, 138), statsPanel)
vipPanel.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
vipPanel.BackgroundTransparency = 0.15
vipPanel.Visible = false
local vipLabel = makeLabel(vipPanel, "VIP")
vipLabel.TextColor3 = Color3.fromRGB(30, 30, 30)
vipLabel.TextXAlignment = Enum.TextXAlignment.Center

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
local promoBanner = makePanel(UDim2.new(0, 440, 0, 120), UDim2.new(0.5, -220, 0.5, -60), screenGui)
promoBanner.Visible = false
promoBanner.BackgroundColor3 = Color3.fromRGB(60, 20, 100)
promoBanner.BackgroundTransparency = 0.1

local promoTitle = makeLabel(promoBanner, "World 1 Complete!")
promoTitle.Size = UDim2.new(1, -12, 0, 30)
promoTitle.Position = UDim2.new(0, 6, 0, 6)
promoTitle.TextXAlignment = Enum.TextXAlignment.Center
promoTitle.TextColor3 = Color3.fromRGB(255, 215, 0)

local promoDesc = makeLabel(promoBanner, Config.CROSS_PROMO_MESSAGE)
promoDesc.Size = UDim2.new(1, -12, 0, 24)
promoDesc.Position = UDim2.new(0, 6, 0, 36)
promoDesc.TextXAlignment = Enum.TextXAlignment.Center
promoDesc.Font = Enum.Font.Gotham

local promoPlayBtn = Instance.new("TextButton")
promoPlayBtn.Size = UDim2.new(0, 140, 0, 34)
promoPlayBtn.Position = UDim2.new(0.5, -75, 1, -10)
promoPlayBtn.AnchorPoint = Vector2.new(0, 1)
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
promoDismissBtn.Size = UDim2.new(0, 100, 0, 34)
promoDismissBtn.Position = UDim2.new(0.5, 75, 1, -10)
promoDismissBtn.AnchorPoint = Vector2.new(0, 1)
promoDismissBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
promoDismissBtn.BorderSizePixel = 0
promoDismissBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
promoDismissBtn.TextScaled = true
promoDismissBtn.Font = Enum.Font.GothamBold
promoDismissBtn.Text = "Later"
promoDismissBtn.Parent = promoBanner

local promoDismissCorner = Instance.new("UICorner")
promoDismissCorner.CornerRadius = UDim.new(0, 8)
promoDismissCorner.Parent = promoDismissBtn

-- Completion overlay (shown when course is finished)
local completionGui = Instance.new("ScreenGui")
completionGui.Name = "ObbyCompletion"
completionGui.ResetOnSpawn = false
completionGui.DisplayOrder = 8
completionGui.Enabled = false
completionGui.Parent = playerGui

local completionBackdrop = Instance.new("Frame")
completionBackdrop.Size = UDim2.new(1, 0, 1, 0)
completionBackdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
completionBackdrop.BackgroundTransparency = 0.5
completionBackdrop.BorderSizePixel = 0
completionBackdrop.Parent = completionGui

local completionPanel = makePanel(UDim2.new(0, 380, 0, 240), UDim2.new(0.5, -190, 0.5, -120), completionGui)
completionPanel.BackgroundTransparency = 0.05

local completionTitle = makeLabel(completionPanel, "Course Complete!")
completionTitle.Size = UDim2.new(1, -12, 0, 36)
completionTitle.Position = UDim2.new(0, 6, 0, 12)
completionTitle.TextXAlignment = Enum.TextXAlignment.Center
completionTitle.TextColor3 = Color3.fromRGB(255, 215, 0)

local completionTimeLabel = makeLabel(completionPanel, "Time: 0:00.00")
completionTimeLabel.Size = UDim2.new(1, -12, 0, 28)
completionTimeLabel.Position = UDim2.new(0, 6, 0, 56)
completionTimeLabel.TextXAlignment = Enum.TextXAlignment.Center

local completionBestLabel = makeLabel(completionPanel, "Best: 0:00.00")
completionBestLabel.Size = UDim2.new(1, -12, 0, 24)
completionBestLabel.Position = UDim2.new(0, 6, 0, 88)
completionBestLabel.TextXAlignment = Enum.TextXAlignment.Center
completionBestLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
completionBestLabel.Font = Enum.Font.GothamMedium

local completionStatsLabel = makeLabel(completionPanel, "Coins: 0  |  Deaths: 0")
completionStatsLabel.Size = UDim2.new(1, -12, 0, 24)
completionStatsLabel.Position = UDim2.new(0, 6, 0, 118)
completionStatsLabel.TextXAlignment = Enum.TextXAlignment.Center
completionStatsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
completionStatsLabel.Font = Enum.Font.GothamMedium

local closeCompletionBtn = Instance.new("TextButton")
closeCompletionBtn.Size = UDim2.new(1, -32, 0, 40)
closeCompletionBtn.Position = UDim2.new(0, 16, 1, -16)
closeCompletionBtn.AnchorPoint = Vector2.new(0, 1)
closeCompletionBtn.BackgroundColor3 = Color3.fromRGB(85, 170, 255)
closeCompletionBtn.BorderSizePixel = 0
closeCompletionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeCompletionBtn.TextScaled = true
closeCompletionBtn.Font = Enum.Font.GothamBold
closeCompletionBtn.Text = "Close"
closeCompletionBtn.Parent = completionPanel

local closeCompletionCorner = Instance.new("UICorner")
closeCompletionCorner.CornerRadius = UDim.new(0, 8)
closeCompletionCorner.Parent = closeCompletionBtn

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
		-- Fallback: fire skip request for testing when product ID not set
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
	-- Ask server to teleport (server-authoritative)
	CrossPromo:FireServer()
end)

promoDismissBtn.Activated:Connect(function()
	promoBanner.Visible = false
end)

closeCompletionBtn.Activated:Connect(function()
	completionGui.Enabled = false
end)

--------------------------------------------------------------------------------
-- Remote event handlers
--------------------------------------------------------------------------------
CheckpointReached.OnClientEvent:Connect(function(num: number, total: number?)
	currentCheckpoint = num
	local stages = total or Config.TOTAL_STAGES

	if num >= stages then
		checkpointLabel.Text = "Course Complete!"
		checkpointLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
		courseComplete = true
		timerRunning = false
	else
		checkpointLabel.Text = "Stage: " .. num .. " / " .. stages
		checkpointLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	end

	-- Start timer on first real checkpoint
	if num >= 2 and not timerRunning and not courseComplete then
		timerRunning = true
		timerStart = os.clock()
	end
end)

CoinCollected.OnClientEvent:Connect(function(coinName: string, newTotal: number)
	totalCoins = newTotal
	coinLabel.Text = "Coins: " .. newTotal

	-- Hide the coin locally
	local coinsFolder = workspace:FindFirstChild("Coins")
	if coinsFolder then
		local coin = coinsFolder:FindFirstChild(coinName)
		if coin and coin:IsA("BasePart") then
			coin.Transparency = 1
			coin.CanCollide = false
			for _, child in coin:GetChildren() do
				pcall(function()
					if child:IsA("BasePart") or child:IsA("Decal") or child:IsA("ParticleEmitter") then
						child.Transparency = 1
					end
				end)
			end
		end
	end
end)

PlayerDied.OnClientEvent:Connect(function(deathCount: number)
	deaths = deathCount
	deathLabel.Text = "Deaths: " .. deathCount
end)

CrossPromo.OnClientEvent:Connect(function()
	promoBanner.Visible = true
end)

StatsSync.OnClientEvent:Connect(function(stats)
	currentCheckpoint = stats.checkpoint or 0
	totalCoins = stats.coins or 0
	deaths = stats.deaths or 0
	isVIP = stats.isVIP or false

	checkpointLabel.Text = "Stage: " .. currentCheckpoint .. " / " .. Config.TOTAL_STAGES
	coinLabel.Text = "Coins: " .. totalCoins
	deathLabel.Text = "Deaths: " .. deaths
	vipPanel.Visible = isVIP

	if stats.completed then
		courseComplete = true
		timerRunning = false
		checkpointLabel.Text = "Course Complete!"
		checkpointLabel.TextColor3 = Color3.fromRGB(255, 215, 0)

		local elapsed = stats.elapsed or 0
		local bestTime = stats.bestTime or 0
		completionTimeLabel.Text = "Time: " .. formatTime(elapsed)
		completionBestLabel.Text = "Best: " .. formatTime(bestTime > 0 and bestTime or elapsed)
		completionStatsLabel.Text = "Coins: " .. totalCoins .. "  |  Deaths: " .. deaths
		completionGui.Enabled = true
	end
end)

PurchaseResult.OnClientEvent:Connect(function(purchaseType: string, success: boolean, data: any?)
	if purchaseType == "vip" and success then
		isVIP = true
		vipPanel.Visible = true
	end

	-- Brief toast notification
	local toastColor = success and Color3.fromRGB(40, 140, 40) or Color3.fromRGB(180, 40, 40)
	local toastText = success and "Purchase successful!" or "Purchase failed."
	if purchaseType == "skip" and success then
		toastText = "Stage skipped!"
	elseif purchaseType == "vip" and success then
		toastText = "VIP activated! Speed boost + 2x coins"
	end

	local toast = makePanel(UDim2.new(0, 300, 0, 40), UDim2.new(0.5, -150, 1, -60), screenGui)
	toast.BackgroundColor3 = toastColor
	toast.BackgroundTransparency = 0.15
	local toastLabel = makeLabel(toast, toastText)
	toastLabel.TextXAlignment = Enum.TextXAlignment.Center
	task.delay(3, function()
		if toast and toast.Parent then
			toast:Destroy()
		end
	end)
end)

--------------------------------------------------------------------------------
-- Timer update loop (client-side for smooth display)
--------------------------------------------------------------------------------
RunService.Heartbeat:Connect(function()
	if timerRunning then
		local elapsed = os.clock() - timerStart
		timerLabel.Text = "Time: " .. formatTime(elapsed)
	end
end)

--------------------------------------------------------------------------------
-- Init
--------------------------------------------------------------------------------
print("[Obby Client] HUD initialized")
