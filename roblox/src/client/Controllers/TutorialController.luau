--[[
	TutorialController.luau
	First-session guided tutorial for new players.

	Shows a step-by-step overlay at the bottom of the screen that advances
	automatically as the player completes each action. Fires TutorialComplete
	to the server when all steps are done, which saves the flag so the tutorial
	is never shown again for this player.

	Tutorial steps (5 total):
	  1. Plant  — click a plot and plant a seed
	  2. Grow   — seed is growing; browse the Journal
	  3. Harvest — plant is ready; click to harvest
	  4. Brew   — open the cauldron and brew a potion
	  5. Sell   — sell the potion for Essence

	State advancement is driven by diffs between consecutive StateSync payloads.
	No server round-trips are needed mid-tutorial; the server is notified only
	at the end (or on skip).

	Architecture note: TutorialController creates its own ScreenGui so it has
	no hard dependency on UIController internals.
]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local Shared  = ReplicatedStorage:WaitForChild("Shared")
local Network = require(Shared:WaitForChild("Network"))
local Strings = require(Shared:WaitForChild("Strings"))

local TutorialController = {}

---------------------------------------------------------------------------
-- Constants
---------------------------------------------------------------------------

local TOTAL_STEPS = 5

local STEP_TEXT: { [number]: string } = {
	[1] = "Step 1/5  —  Welcome! Click a garden plot to plant your first Moonpetal seed.",
	[2] = "Step 2/5  —  Growing! Open the Alchemist's Journal to learn the science while you wait.",
	[3] = "Step 3/5  —  Your plant is ready! Click the glowing plot to harvest it.",
	[4] = "Step 4/5  —  Ingredient collected! Click the cauldron to brew your first potion.",
	[5] = "Step 5/5  —  Potion brewed! Sell it at the shop — click Sell to collect your Essence.",
}

local COMPLETE_TEXT = "You're a real Alchemist now!  Keep discovering new recipes."

local PANEL_COLOR  = Color3.fromRGB(25, 25, 40)
local ACCENT_COLOR = Color3.fromRGB(100, 80, 200)
local TEXT_COLOR   = Color3.fromRGB(230, 230, 255)
local GOLD_COLOR   = Color3.fromRGB(255, 215, 0)

---------------------------------------------------------------------------
-- Module state
---------------------------------------------------------------------------

local remotes: Folder     = nil :: any
local tutorialGui: ScreenGui = nil :: any
local tutorialFrame: Frame   = nil :: any
local stepLabel: TextLabel   = nil :: any
local progressFill: Frame    = nil :: any

local initialized = false -- true after first StateSync has been processed
local isActive    = false -- true while tutorial is running
local currentStep = 1
local prevState: { [string]: any } = {}

---------------------------------------------------------------------------
-- State helpers (pure functions, no side effects)
---------------------------------------------------------------------------

local function countArray(t: { any }?): number
	if not t then return 0 end
	return #t
end

local function hasPlotInState(state: { [string]: any }?, targetState: string): boolean
	if not state or not state.Plots then return false end
	for _, plot in state.Plots do
		if plot.State == targetState then return true end
	end
	return false
end

---------------------------------------------------------------------------
-- UI helpers
---------------------------------------------------------------------------

local function tweenProgressBar(step: number)
	if not progressFill then return end
	-- Fill fraction = steps completed / total (we fill on completion of each step)
	local frac = math.clamp((step - 1) / TOTAL_STEPS, 0, 1)
	TweenService:Create(
		progressFill,
		TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = UDim2.new(frac, 0, 1, 0) }
	):Play()
end

local function setStepLabel(text: string, color: Color3?)
	if stepLabel then
		stepLabel.Text = text
		stepLabel.TextColor3 = color or TEXT_COLOR
	end
end

local function fireComplete()
	if not remotes then return end
	local remote = remotes:FindFirstChild(Network.TutorialComplete)
	if remote then
		(remote :: RemoteEvent):FireServer()
	end
end

local function hideTutorial()
	if not tutorialFrame then return end
	local tween = TweenService:Create(
		tutorialFrame,
		TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ Position = UDim2.new(0.5, 0, 1, 80) }
	)
	tween:Play()
	tween.Completed:Connect(function()
		if tutorialGui then
			tutorialGui:Destroy()
			tutorialGui = nil
			tutorialFrame = nil
			stepLabel = nil
			progressFill = nil
		end
	end)
	isActive = false
end

local function advanceTo(step: number)
	if step > TOTAL_STEPS then
		-- Tutorial complete
		setStepLabel(COMPLETE_TEXT, GOLD_COLOR)
		tweenProgressBar(TOTAL_STEPS + 1)
		fireComplete()
		task.delay(4, hideTutorial)
		isActive = false
		return
	end

	currentStep = step
	setStepLabel(STEP_TEXT[step])
	tweenProgressBar(step)
end

---------------------------------------------------------------------------
-- UI construction
---------------------------------------------------------------------------

local function buildOverlay()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	-- Dedicated ScreenGui so ZIndex is independent of the main game UI
	tutorialGui = Instance.new("ScreenGui")
	tutorialGui.Name = "TutorialUI"
	tutorialGui.ResetOnSpawn = false
	tutorialGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	tutorialGui.DisplayOrder = 5  -- above game UI (default 0)
	tutorialGui.Parent = playerGui

	-- Main tutorial bar (starts below screen, slides up)
	tutorialFrame = Instance.new("Frame")
	tutorialFrame.Name = "TutorialBar"
	tutorialFrame.Size = UDim2.new(0, 500, 0, 76)
	tutorialFrame.Position = UDim2.new(0.5, 0, 1, 80)  -- offscreen below
	tutorialFrame.AnchorPoint = Vector2.new(0.5, 1)
	tutorialFrame.BackgroundColor3 = PANEL_COLOR
	tutorialFrame.BackgroundTransparency = 0.08
	tutorialFrame.BorderSizePixel = 0
	tutorialFrame.ZIndex = 30
	tutorialFrame.Parent = tutorialGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = tutorialFrame

	local stroke = Instance.new("UIStroke")
	stroke.Color = ACCENT_COLOR
	stroke.Thickness = 2
	stroke.Parent = tutorialFrame

	-- Step instruction label
	stepLabel = Instance.new("TextLabel")
	stepLabel.Name = "StepLabel"
	stepLabel.Size = UDim2.new(1, -56, 0, 44)
	stepLabel.Position = UDim2.new(0, 10, 0, 6)
	stepLabel.BackgroundTransparency = 1
	stepLabel.Font = Enum.Font.GothamMedium
	stepLabel.TextSize = 14
	stepLabel.TextColor3 = TEXT_COLOR
	stepLabel.TextWrapped = true
	stepLabel.TextXAlignment = Enum.TextXAlignment.Left
	stepLabel.ZIndex = 31
	stepLabel.Parent = tutorialFrame
	stepLabel.Text = STEP_TEXT[1]

	-- Progress bar track
	local progressTrack = Instance.new("Frame")
	progressTrack.Name = "ProgressTrack"
	progressTrack.Size = UDim2.new(1, -20, 0, 6)
	progressTrack.Position = UDim2.new(0, 10, 1, -14)
	progressTrack.BackgroundColor3 = Color3.fromRGB(55, 55, 75)
	progressTrack.BorderSizePixel = 0
	progressTrack.ZIndex = 31
	progressTrack.Parent = tutorialFrame

	local trackCorner = Instance.new("UICorner")
	trackCorner.CornerRadius = UDim.new(1, 0)
	trackCorner.Parent = progressTrack

	-- Progress bar fill (starts at zero width)
	progressFill = Instance.new("Frame")
	progressFill.Name = "Fill"
	progressFill.Size = UDim2.new(0, 0, 1, 0)
	progressFill.BackgroundColor3 = ACCENT_COLOR
	progressFill.BorderSizePixel = 0
	progressFill.ZIndex = 32
	progressFill.Parent = progressTrack

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = progressFill

	-- Skip button (top-right of bar)
	local skipBtn = Instance.new("TextButton")
	skipBtn.Name = "SkipBtn"
	skipBtn.Text = Strings.SKIP
	skipBtn.Font = Enum.Font.GothamMedium
	skipBtn.TextSize = 12
	skipBtn.TextColor3 = Color3.fromRGB(140, 140, 160)
	skipBtn.BackgroundTransparency = 1
	skipBtn.Size = UDim2.new(0, 40, 0, 20)
	skipBtn.Position = UDim2.new(1, -46, 0, 6)
	skipBtn.ZIndex = 32
	skipBtn.Parent = tutorialFrame

	skipBtn.Activated:Connect(function()
		fireComplete()
		hideTutorial()
	end)

	-- Slide in from below after a short delay (gives main UI time to settle)
	task.delay(0.8, function()
		if not tutorialFrame then return end
		TweenService:Create(
			tutorialFrame,
			TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Position = UDim2.new(0.5, 0, 1, -16) }
		):Play()
	end)
end

---------------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------------

--- Store dependencies. Called once from Main.client.luau before StateSync fires.
function TutorialController.init(remotesFolder: Folder)
	remotes = remotesFolder
end

--- Called on every StateSync payload. Decides whether to start, advance,
--- or skip the tutorial based on the player's saved data and state diffs.
function TutorialController.onStateChanged(newState: { [string]: any })
	if not newState then return end

	if not initialized then
		initialized = true
		-- New player: TutorialCompleted is false (default from DATA_TEMPLATE)
		-- Returning player who finished: TutorialCompleted is true
		if newState.TutorialCompleted then
			-- Tutorial already done — nothing to do
			isActive = false
		else
			-- First session — build the overlay and start
			isActive = true
			currentStep = 1
			prevState = newState
			buildOverlay()
		end
		return
	end

	if not isActive then return end

	-- Advance through steps based on state diffs
	if currentStep == 1 then
		-- Step complete when any plot transitions to Growing (seed planted)
		local wasGrowing = hasPlotInState(prevState, "Growing") or hasPlotInState(prevState, "Ready")
		local nowGrowing = hasPlotInState(newState, "Growing") or hasPlotInState(newState, "Ready")
		if nowGrowing and not wasGrowing then
			advanceTo(2)
		end

	elseif currentStep == 2 then
		-- Step complete when any plot becomes Ready (fully grown)
		if hasPlotInState(newState, "Ready") and not hasPlotInState(prevState, "Ready") then
			advanceTo(3)
		end

	elseif currentStep == 3 then
		-- Step complete when ingredients count increases (harvested)
		if countArray(newState.Ingredients) > countArray(prevState.Ingredients) then
			advanceTo(4)
		end

	elseif currentStep == 4 then
		-- Step complete when potions count increases (brewed)
		if countArray(newState.Potions) > countArray(prevState.Potions) then
			advanceTo(5)
		end

	elseif currentStep == 5 then
		-- Step complete when potions count decreases AND was previously > 0 (sold)
		local prevPotions = countArray(prevState.Potions)
		local nowPotions = countArray(newState.Potions)
		if prevPotions > 0 and nowPotions < prevPotions then
			advanceTo(TOTAL_STEPS + 1) -- triggers completion sequence
		end
	end

	prevState = newState
end

return TutorialController
