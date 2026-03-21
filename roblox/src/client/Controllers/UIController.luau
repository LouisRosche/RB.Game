--[[
	UIController.luau
	Creates and manages ALL game UI programmatically.
	Panels: HUD, Seed Selection, Brewing, Sell, Upgrades, Notifications, Journal.

	Design philosophy:
	  - Every interaction is celebratory, never pressuring
	  - The Journal panel teaches real science through the game
	  - Odds are shown transparently — no mystery about probability
	  - Notifications are warm and informative, never guilt-tripping

	Follows the Single-Script Architecture — this is a ModuleScript required
	by Main.client.luau.
]]

---------------------------------------------------------------------------
-- Services
---------------------------------------------------------------------------
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local PolicyService     = game:GetService("PolicyService")

---------------------------------------------------------------------------
-- Shared modules
---------------------------------------------------------------------------
local MarketplaceService = game:GetService("MarketplaceService")

local Shared      = ReplicatedStorage:WaitForChild("Shared")
local Config      = require(Shared:WaitForChild("Config"))
local Ingredients = require(Shared:WaitForChild("Ingredients"))
local Recipes     = require(Shared:WaitForChild("Recipes"))
local Strings     = require(Shared:WaitForChild("Strings"))
local Network     = require(Shared:WaitForChild("Network"))
local Journal     = require(Shared:WaitForChild("Journal"))
local Cosmetics   = require(Shared:WaitForChild("Cosmetics"))
local GamePasses  = require(Shared:WaitForChild("GamePasses"))

---------------------------------------------------------------------------
-- Constants — UI Style Guide
---------------------------------------------------------------------------
local PANEL_BG_COLOR      = Color3.fromRGB(30, 30, 45)
local PANEL_BG_TRANSPARENCY = 0.15 -- BackgroundTransparency (0.85 opaque → 0.15 transparency)
local PANEL_STROKE_COLOR  = Color3.fromRGB(100, 80, 200)
local PANEL_STROKE_THICKNESS = 2
local TEXT_COLOR           = Color3.fromRGB(230, 230, 255)
local BUTTON_COLOR         = Color3.fromRGB(80, 60, 160)
local BUTTON_HOVER_COLOR   = Color3.fromRGB(100, 80, 180)
local GOLD_TEXT_COLOR      = Color3.fromRGB(255, 215, 0)
local CORNER_RADIUS        = UDim.new(0, 8)
local PADDING              = UDim.new(0, 8)
local FONT_HEADER          = Enum.Font.GothamBold
local FONT_BODY            = Enum.Font.GothamMedium

---------------------------------------------------------------------------
-- Module
---------------------------------------------------------------------------
local UIController = {}

-- Private state
local playerState: { [string]: any } = {}
local remotes: Folder = nil :: any
local screenGui: ScreenGui = nil :: any
local soundController: any = nil  -- optional; injected via init()

-- UI element references (set during init)
local hudGoldLabel: TextLabel = nil :: any
local hudLabLabel: TextLabel = nil :: any
local hudCauldronLabel: TextLabel = nil :: any

local seedPanel: Frame = nil :: any
local brewPanel: Frame = nil :: any
local sellPanel: Frame = nil :: any
local upgradePanel: Frame = nil :: any
local journalPanel: Frame = nil :: any
local settingsPanel: Frame = nil :: any
local cosmeticPanel: Frame = nil :: any
local leaderboardPanel: Frame = nil :: any
local notificationContainer: Frame = nil :: any

-- Volume state for settings panel (percent 0–100, matches SoundController defaults)
local musicVolumePct = 18
local sfxVolumePct   = 55
local settingsMusicLabel: TextLabel = nil :: any
local settingsSFXLabel: TextLabel   = nil :: any

-- Performance-mode controllers (injected after init via setPerformanceControllers)
local lightingController: any = nil
local particleController: any = nil

-- Leaderboard row labels (reused on each update to avoid re-creating UI)
local leaderboardRowLabels: { TextLabel } = {}

-- PolicyService flags (set asynchronously during HUD creation)
local adsAllowed: boolean = false
local externalLinksAllowed: boolean = true -- default true, overridden by PolicyService
local paidRandomItemsRestricted: boolean = false -- precautionary; no loot boxes but rarity rolls exist

-- Rewarded ad button state
local adButton: TextButton = nil :: any
local adCooldownLabel: TextLabel = nil :: any
local adCooldownRemaining: number = 0
-- NOTE: adsAllowed is defined above (line 95) with PolicyService flags
local adCooldownConnection: RBXScriptConnection? = nil

-- Brewing selection state
local selectedIngredients: { number } = {}
local brewIngredientButtons: { Frame } = {}
local brewButton: TextButton = nil :: any
local brewPreviewLabel: TextLabel = nil :: any

-- Seed panel context
local activePlotIndex: number? = nil

---------------------------------------------------------------------------
-- Helpers — UI Factory
---------------------------------------------------------------------------

--- Creates a Frame with the standard panel styling (dark background, stroke, corner).
local function createPanel(name: string, size: UDim2, position: UDim2): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Size = size
	frame.Position = position
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundColor3 = PANEL_BG_COLOR
	frame.BackgroundTransparency = PANEL_BG_TRANSPARENCY
	frame.BorderSizePixel = 0
	frame.Visible = false
	frame.ZIndex = 10

	local corner = Instance.new("UICorner")
	corner.CornerRadius = CORNER_RADIUS
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = PANEL_STROKE_COLOR
	stroke.Thickness = PANEL_STROKE_THICKNESS
	stroke.Parent = frame

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = PADDING
	padding.PaddingBottom = PADDING
	padding.PaddingLeft = PADDING
	padding.PaddingRight = PADDING
	padding.Parent = frame

	return frame
end

--- Creates a styled TextLabel.
local function createLabel(name: string, text: string, font: Enum.Font, size: number, parent: GuiObject): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Text = text
	label.Font = font
	label.TextSize = size
	label.TextColor3 = TEXT_COLOR
	label.BackgroundTransparency = 1
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Size = UDim2.new(1, 0, 0, size + 8)
	label.Parent = parent
	return label
end

--- Creates a styled TextButton.
local function createButton(name: string, text: string, size: UDim2, parent: GuiObject): TextButton
	local button = Instance.new("TextButton")
	button.Name = name
	button.Text = text
	button.Font = FONT_BODY
	button.TextSize = 16
	button.TextColor3 = TEXT_COLOR
	button.BackgroundColor3 = BUTTON_COLOR
	button.Size = size
	button.BorderSizePixel = 0
	button.AutoButtonColor = false
	button.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = CORNER_RADIUS
	corner.Parent = button

	-- Hover effects
	button.MouseEnter:Connect(function()
		button.BackgroundColor3 = BUTTON_HOVER_COLOR
	end)
	button.MouseLeave:Connect(function()
		button.BackgroundColor3 = BUTTON_COLOR
	end)

	return button
end

--- Creates a small coloured circle to represent an ingredient / potion colour.
local function createColorIcon(color: Color3, size: number, parent: GuiObject): Frame
	local icon = Instance.new("Frame")
	icon.Name = "ColorIcon"
	icon.Size = UDim2.new(0, size, 0, size)
	icon.BackgroundColor3 = color
	icon.BorderSizePixel = 0
	icon.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = icon

	return icon
end

--- Creates a close button (X) in the top-right of a panel.
local function createCloseButton(panel: Frame): TextButton
	local btn = Instance.new("TextButton")
	btn.Name = "CloseButton"
	btn.Text = "X"
	btn.Font = FONT_HEADER
	btn.TextSize = 18
	btn.TextColor3 = TEXT_COLOR
	btn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
	btn.Size = UDim2.new(0, 30, 0, 30)
	btn.Position = UDim2.new(1, -30, 0, 0)
	btn.BorderSizePixel = 0
	btn.ZIndex = 15
	btn.Parent = panel

	local corner = Instance.new("UICorner")
	corner.CornerRadius = CORNER_RADIUS
	corner.Parent = btn

	btn.MouseEnter:Connect(function()
		btn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
	end)
	btn.MouseLeave:Connect(function()
		btn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
	end)

	btn.Activated:Connect(function()
		UIController.closePanels()
	end)

	return btn
end

--- Fires a RemoteEvent by name with the given arguments.
local function fireRemote(eventName: string, ...: any)
	local remote = remotes:FindFirstChild(eventName)
	if remote then
		(remote :: RemoteEvent):FireServer(...)
	end
end

--- Replaces {placeholder} tokens in a Strings template.
local function formatString(template: string, replacements: { [string]: string | number }): string
	local result = template
	for key, value in replacements do
		result = string.gsub(result, "{" .. key .. "}", tostring(value))
	end
	return result
end

--- Returns the Color3 for a given rarity name from MutationTiers.
local function getRarityColor(rarityName: string): Color3
	for _, tier in Config.MUTATION_TIERS do
		if tier.name == rarityName then
			return tier.color
		end
	end
	return TEXT_COLOR
end

--- Creates a ScrollingFrame suitable for lists inside panels.
local function createScrollingList(name: string, size: UDim2, position: UDim2, parent: GuiObject): ScrollingFrame
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = name
	scroll.Size = size
	scroll.Position = position
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 6
	scroll.ScrollBarImageColor3 = PANEL_STROKE_COLOR
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0) -- will be resized dynamically
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.ZIndex = 11
	scroll.Parent = parent

	local layout = Instance.new("UIListLayout")
	layout.Name = "ListLayout"
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 4)
	layout.Parent = scroll

	return scroll
end

---------------------------------------------------------------------------
-- HUD (always visible, top of screen)
---------------------------------------------------------------------------

local function createHUD()
	-- Container
	local hud = Instance.new("Frame")
	hud.Name = "HUD"
	hud.Size = UDim2.new(0, 220, 0, 232)
	hud.Position = UDim2.new(0, 10, 0, 10)
	hud.BackgroundColor3 = PANEL_BG_COLOR
	hud.BackgroundTransparency = PANEL_BG_TRANSPARENCY
	hud.BorderSizePixel = 0
	hud.ZIndex = 5
	hud.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = CORNER_RADIUS
	corner.Parent = hud

	local stroke = Instance.new("UIStroke")
	stroke.Color = PANEL_STROKE_COLOR
	stroke.Thickness = PANEL_STROKE_THICKNESS
	stroke.Parent = hud

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = PADDING
	padding.PaddingBottom = PADDING
	padding.PaddingLeft = PADDING
	padding.PaddingRight = PADDING
	padding.Parent = hud

	-- Gold icon (yellow circle)
	local goldIcon = createColorIcon(GOLD_TEXT_COLOR, 20, hud)
	goldIcon.Position = UDim2.new(0, 0, 0, 2)

	-- Gold label
	hudGoldLabel = Instance.new("TextLabel")
	hudGoldLabel.Name = "GoldLabel"
	hudGoldLabel.Size = UDim2.new(1, -28, 0, 24)
	hudGoldLabel.Position = UDim2.new(0, 28, 0, 0)
	hudGoldLabel.BackgroundTransparency = 1
	hudGoldLabel.Font = FONT_HEADER
	hudGoldLabel.TextSize = 20
	hudGoldLabel.TextColor3 = GOLD_TEXT_COLOR
	hudGoldLabel.TextXAlignment = Enum.TextXAlignment.Left
	hudGoldLabel.Text = Strings.GOLD .. ": 0"
	hudGoldLabel.ZIndex = 6
	hudGoldLabel.Parent = hud

	-- Lab level label
	hudLabLabel = Instance.new("TextLabel")
	hudLabLabel.Name = "LabLabel"
	hudLabLabel.Size = UDim2.new(1, 0, 0, 22)
	hudLabLabel.Position = UDim2.new(0, 0, 0, 30)
	hudLabLabel.BackgroundTransparency = 1
	hudLabLabel.Font = FONT_BODY
	hudLabLabel.TextSize = 16
	hudLabLabel.TextColor3 = TEXT_COLOR
	hudLabLabel.TextXAlignment = Enum.TextXAlignment.Left
	hudLabLabel.Text = Strings.HUD_LAB_DEFAULT
	hudLabLabel.ZIndex = 6
	hudLabLabel.Parent = hud

	-- Cauldron level label
	hudCauldronLabel = Instance.new("TextLabel")
	hudCauldronLabel.Name = "CauldronLabel"
	hudCauldronLabel.Size = UDim2.new(1, 0, 0, 22)
	hudCauldronLabel.Position = UDim2.new(0, 0, 0, 56)
	hudCauldronLabel.BackgroundTransparency = 1
	hudCauldronLabel.Font = FONT_BODY
	hudCauldronLabel.TextSize = 16
	hudCauldronLabel.TextColor3 = TEXT_COLOR
	hudCauldronLabel.TextXAlignment = Enum.TextXAlignment.Left
	hudCauldronLabel.Text = Strings.HUD_CAULDRON_DEFAULT
	hudCauldronLabel.ZIndex = 6
	hudCauldronLabel.Parent = hud

	-- Journal button (always accessible from HUD)
	local journalBtn = createButton("JournalBtn", Strings.JOURNAL, UDim2.new(1, 0, 0, 28), hud)
	journalBtn.Position = UDim2.new(0, 0, 0, 84)
	journalBtn.TextSize = 14
	journalBtn.BackgroundColor3 = Color3.fromRGB(50, 80, 130)
	journalBtn.ZIndex = 6

	journalBtn.MouseEnter:Connect(function()
		journalBtn.BackgroundColor3 = Color3.fromRGB(70, 100, 160)
	end)
	journalBtn.MouseLeave:Connect(function()
		journalBtn.BackgroundColor3 = Color3.fromRGB(50, 80, 130)
	end)

	journalBtn.Activated:Connect(function()
		UIController.openJournalPanel()
	end)

	-- Settings button (volume / accessibility controls)
	local settingsBtn = createButton("SettingsBtn", "⚙ " .. Strings.SETTINGS, UDim2.new(1, 0, 0, 26), hud)
	settingsBtn.Position = UDim2.new(0, 0, 0, 118)
	settingsBtn.TextSize = 13
	settingsBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 70)
	settingsBtn.ZIndex = 6

	settingsBtn.MouseEnter:Connect(function()
		settingsBtn.BackgroundColor3 = Color3.fromRGB(65, 65, 90)
	end)
	settingsBtn.MouseLeave:Connect(function()
		settingsBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 70)
	end)

	settingsBtn.Activated:Connect(function()
		UIController.openSettingsPanel()
	end)

	-- Cosmetic Shop button
	local cosmeticBtn = createButton("CosmeticBtn", Strings.COSMETIC_SHOP, UDim2.new(1, 0, 0, 26), hud)
	cosmeticBtn.Position = UDim2.new(0, 0, 0, 150)
	cosmeticBtn.TextSize = 13
	cosmeticBtn.BackgroundColor3 = Color3.fromRGB(100, 50, 120)
	cosmeticBtn.ZIndex = 6

	cosmeticBtn.MouseEnter:Connect(function()
		cosmeticBtn.BackgroundColor3 = Color3.fromRGB(130, 70, 155)
	end)
	cosmeticBtn.MouseLeave:Connect(function()
		cosmeticBtn.BackgroundColor3 = Color3.fromRGB(100, 50, 120)
	end)

	cosmeticBtn.Activated:Connect(function()
		UIController.openCosmeticPanel()
	end)

	-- Watch Ad button (hidden by default; shown only if ads are allowed for this player)
	adButton = createButton("AdBtn", Strings.AD_WATCH_BUTTON, UDim2.new(1, 0, 0, 26), hud)
	adButton.Position = UDim2.new(0, 0, 0, 182)
	adButton.TextSize = 13
	adButton.BackgroundColor3 = Color3.fromRGB(40, 130, 60)
	adButton.ZIndex = 6
	adButton.Visible = false -- hidden until PolicyService confirms ads are allowed

	adButton.MouseEnter:Connect(function()
		if adCooldownRemaining <= 0 then
			adButton.BackgroundColor3 = Color3.fromRGB(60, 160, 80)
		end
	end)
	adButton.MouseLeave:Connect(function()
		if adCooldownRemaining <= 0 then
			adButton.BackgroundColor3 = Color3.fromRGB(40, 130, 60)
		end
	end)

	adButton.Activated:Connect(function()
		if adCooldownRemaining > 0 then return end
		if not remotes then return end
		local remote = remotes:FindFirstChild(Network.RequestAdReward) :: RemoteEvent
		if remote then
			remote:FireServer()
		end
	end)

	-- Cooldown sub-label (shows remaining time beneath the button text)
	adCooldownLabel = Instance.new("TextLabel")
	adCooldownLabel.Name = "AdCooldownLabel"
	adCooldownLabel.Size = UDim2.new(1, 0, 0, 14)
	adCooldownLabel.Position = UDim2.new(0, 0, 1, -14)
	adCooldownLabel.BackgroundTransparency = 1
	adCooldownLabel.Font = FONT_BODY
	adCooldownLabel.TextSize = 11
	adCooldownLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	adCooldownLabel.Text = ""
	adCooldownLabel.ZIndex = 7
	adCooldownLabel.Visible = false
	adCooldownLabel.Parent = adButton

	-- Check PolicyService for region-specific restrictions (ads, external links)
	task.spawn(function()
		local ok, policyInfo = pcall(function()
			return PolicyService:GetPolicyInfoForPlayerAsync(Players.LocalPlayer)
		end)
		if ok and policyInfo then
			-- Ads
			if policyInfo.AreAdsAllowed then
				adsAllowed = true
				adButton.Visible = true
			else
				adsAllowed = false
				adButton.Visible = false
				hud.Size = UDim2.new(0, 220, 0, 196)
			end
			-- External links (Discord, website) — respect AllowedExternalLinkReferences
			if policyInfo.AllowedExternalLinkReferences then
				externalLinksAllowed = #policyInfo.AllowedExternalLinkReferences > 0
			end
			-- Paid random items (precautionary — game has no loot boxes but rarity
			-- rolls on harvest could be interpreted as paid-random in strict jurisdictions)
			if policyInfo.ArePaidRandomItemsRestricted then
				paidRandomItemsRestricted = true
			end
		else
			adsAllowed = false
			adButton.Visible = false
			hud.Size = UDim2.new(0, 220, 0, 196)
		end
	end)
end

---------------------------------------------------------------------------
-- Seed Selection Panel (opens when clicking an empty plot)
---------------------------------------------------------------------------

local function createSeedPanel()
	seedPanel = createPanel("SeedPanel", UDim2.new(0, 320, 0, 340), UDim2.new(0.5, 0, 0.5, 0))
	seedPanel.Parent = screenGui

	-- Title
	local title = createLabel("Title", "Select a Seed to Plant", FONT_HEADER, 20, seedPanel)
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.Size = UDim2.new(1, -40, 0, 30)

	-- Close button
	createCloseButton(seedPanel)

	-- Seed list container
	local seedList = Instance.new("Frame")
	seedList.Name = "SeedList"
	seedList.Size = UDim2.new(1, 0, 1, -44)
	seedList.Position = UDim2.new(0, 0, 0, 40)
	seedList.BackgroundTransparency = 1
	seedList.ZIndex = 11
	seedList.Parent = seedPanel

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 6)
	layout.Parent = seedList

	-- Create a button for each ingredient
	local ingredientList = Ingredients.getList()
	for i, entry in ingredientList do
		local def = entry.def
		local id = entry.id

		local row = Instance.new("Frame")
		row.Name = "Seed_" .. id
		row.Size = UDim2.new(1, 0, 0, 60)
		row.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
		row.BackgroundTransparency = 0.3
		row.BorderSizePixel = 0
		row.LayoutOrder = i
		row.ZIndex = 12
		row.Parent = seedList

		local rowCorner = Instance.new("UICorner")
		rowCorner.CornerRadius = UDim.new(0, 6)
		rowCorner.Parent = row

		-- Ingredient colour icon
		local icon = createColorIcon(def.color, 28, row)
		icon.Position = UDim2.new(0, 8, 0.5, -14)
		icon.ZIndex = 13

		-- Name
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "NameLabel"
		nameLabel.Text = def.displayName
		nameLabel.Font = FONT_HEADER
		nameLabel.TextSize = 16
		nameLabel.TextColor3 = TEXT_COLOR
		nameLabel.BackgroundTransparency = 1
		nameLabel.Size = UDim2.new(0.5, -44, 0, 20)
		nameLabel.Position = UDim2.new(0, 44, 0, 6)
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.ZIndex = 13
		nameLabel.Parent = row

		-- Info (cost + growth time)
		local infoLabel = Instance.new("TextLabel")
		infoLabel.Name = "InfoLabel"
		infoLabel.Text = formatString(Strings.SEED_COST_LABEL, { cost = def.seedCost })
			.. "  |  "
			.. formatString(Strings.GROWTH_LABEL, { time = def.growthTime })
		infoLabel.Font = FONT_BODY
		infoLabel.TextSize = 13
		infoLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
		infoLabel.BackgroundTransparency = 1
		infoLabel.Size = UDim2.new(0.6, -44, 0, 16)
		infoLabel.Position = UDim2.new(0, 44, 0, 30)
		infoLabel.TextXAlignment = Enum.TextXAlignment.Left
		infoLabel.ZIndex = 13
		infoLabel.Parent = row

		-- Plant button
		local plantBtn = createButton("PlantBtn", Strings.PLANT .. " (-" .. def.seedCost .. " E)", UDim2.new(0, 90, 0, 36), row)
		plantBtn.Position = UDim2.new(1, -98, 0.5, -18)
		plantBtn.ZIndex = 14

		plantBtn.Activated:Connect(function()
			if activePlotIndex then
				if soundController then soundController.onPlant() end
				fireRemote(Network.PlantSeed, activePlotIndex, id)
				UIController.closePanels()
			end
		end)
	end
end

---------------------------------------------------------------------------
-- Brewing Panel (opens when clicking cauldron)
---------------------------------------------------------------------------

local function populateBrewIngredients()
	-- Clear existing buttons
	for _, btn in brewIngredientButtons do
		btn:Destroy()
	end
	table.clear(brewIngredientButtons)
	table.clear(selectedIngredients)

	local scroll = brewPanel:FindFirstChild("IngredientScroll") :: ScrollingFrame
	if not scroll then return end

	local ingredients = playerState.Ingredients
	if not ingredients or #ingredients == 0 then
		local emptyLabel = Instance.new("TextLabel")
		emptyLabel.Name = "EmptyLabel"
		emptyLabel.Text = Strings.NO_INGREDIENTS
		emptyLabel.Font = FONT_BODY
		emptyLabel.TextSize = 16
		emptyLabel.TextColor3 = Color3.fromRGB(150, 150, 170)
		emptyLabel.BackgroundTransparency = 1
		emptyLabel.Size = UDim2.new(1, 0, 0, 30)
		emptyLabel.ZIndex = 12
		emptyLabel.Parent = scroll
		table.insert(brewIngredientButtons, emptyLabel)
		return
	end

	for i, entry in ingredients do
		local def = Ingredients[entry.Id]
		if not def then continue end

		local row = Instance.new("Frame")
		row.Name = "IngEntry_" .. i
		row.Size = UDim2.new(1, 0, 0, 40)
		row.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
		row.BackgroundTransparency = 0.3
		row.BorderSizePixel = 0
		row.LayoutOrder = i
		row.ZIndex = 12
		row.Parent = scroll

		local rowCorner = Instance.new("UICorner")
		rowCorner.CornerRadius = UDim.new(0, 6)
		rowCorner.Parent = row

		-- Colour icon
		local icon = createColorIcon(def.color, 22, row)
		icon.Position = UDim2.new(0, 6, 0.5, -11)
		icon.ZIndex = 13

		-- Name
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "Name"
		nameLabel.Text = def.displayName
		nameLabel.Font = FONT_BODY
		nameLabel.TextSize = 15
		nameLabel.TextColor3 = TEXT_COLOR
		nameLabel.BackgroundTransparency = 1
		nameLabel.Size = UDim2.new(0.4, -36, 1, 0)
		nameLabel.Position = UDim2.new(0, 36, 0, 0)
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.ZIndex = 13
		nameLabel.Parent = row

		-- Rarity
		local rarityLabel = Instance.new("TextLabel")
		rarityLabel.Name = "Rarity"
		rarityLabel.Text = entry.Rarity or "Common"
		rarityLabel.Font = FONT_BODY
		rarityLabel.TextSize = 14
		rarityLabel.TextColor3 = getRarityColor(entry.Rarity or "Common")
		rarityLabel.BackgroundTransparency = 1
		rarityLabel.Size = UDim2.new(0.3, 0, 1, 0)
		rarityLabel.Position = UDim2.new(0.4, 0, 0, 0)
		rarityLabel.TextXAlignment = Enum.TextXAlignment.Center
		rarityLabel.ZIndex = 13
		rarityLabel.Parent = row

		-- Selection indicator
		local selectIndicator = Instance.new("Frame")
		selectIndicator.Name = "SelectIndicator"
		selectIndicator.Size = UDim2.new(0, 24, 0, 24)
		selectIndicator.Position = UDim2.new(1, -32, 0.5, -12)
		selectIndicator.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
		selectIndicator.BorderSizePixel = 0
		selectIndicator.ZIndex = 13
		selectIndicator.Parent = row

		local indicatorCorner = Instance.new("UICorner")
		indicatorCorner.CornerRadius = UDim.new(0, 4)
		indicatorCorner.Parent = selectIndicator

		local indicatorStroke = Instance.new("UIStroke")
		indicatorStroke.Color = PANEL_STROKE_COLOR
		indicatorStroke.Thickness = 1
		indicatorStroke.Parent = selectIndicator

		-- Make the row clickable
		local clickBtn = Instance.new("TextButton")
		clickBtn.Name = "ClickArea"
		clickBtn.Text = ""
		clickBtn.Size = UDim2.new(1, 0, 1, 0)
		clickBtn.BackgroundTransparency = 1
		clickBtn.ZIndex = 14
		clickBtn.Parent = row

		clickBtn.Activated:Connect(function()
			-- Toggle selection
			local alreadySelected = table.find(selectedIngredients, i)
			if alreadySelected then
				table.remove(selectedIngredients, alreadySelected)
				selectIndicator.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
				row.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
			elseif #selectedIngredients < 2 then
				table.insert(selectedIngredients, i)
				selectIndicator.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
				row.BackgroundColor3 = Color3.fromRGB(55, 55, 85)
			end

			-- Update brew button state
			if brewButton then
				brewButton.BackgroundColor3 = if #selectedIngredients == 2 then Color3.fromRGB(60, 160, 60) else BUTTON_COLOR
			end

			-- Update preview label
			if brewPreviewLabel then
				if #selectedIngredients == 2 then
					local ing1 = ingredients[selectedIngredients[1]]
					local ing2 = ingredients[selectedIngredients[2]]
					if ing1 and ing2 then
						local recipe = Recipes.lookup(ing1.Id, ing2.Id)
						if recipe then
							brewPreviewLabel.Text = formatString(Strings.BREW_PREVIEW, {
								potion = recipe.displayName,
								value = recipe.baseValue,
							})
							brewPreviewLabel.TextColor3 = recipe.color
						else
							brewPreviewLabel.Text = Strings.UNKNOWN_RECIPE
							brewPreviewLabel.TextColor3 = Color3.fromRGB(200, 100, 100)
						end
					end
				else
					brewPreviewLabel.Text = Strings.SELECT_TO_BREW
					brewPreviewLabel.TextColor3 = Color3.fromRGB(150, 150, 170)
				end
			end
		end)

		table.insert(brewIngredientButtons, row)
	end
end

local function createBrewPanel()
	brewPanel = createPanel("BrewPanel", UDim2.new(0, 360, 0, 440), UDim2.new(0.5, 0, 0.5, 0))
	brewPanel.Parent = screenGui

	-- Title
	local title = createLabel("Title", "Cauldron", FONT_HEADER, 22, brewPanel)
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.Size = UDim2.new(1, -40, 0, 30)

	createCloseButton(brewPanel)

	-- Scrolling ingredient list
	local scroll = createScrollingList(
		"IngredientScroll",
		UDim2.new(1, 0, 1, -120),
		UDim2.new(0, 0, 0, 40),
		brewPanel
	)
	scroll.ZIndex = 11

	-- Preview label
	brewPreviewLabel = Instance.new("TextLabel")
	brewPreviewLabel.Name = "PreviewLabel"
	brewPreviewLabel.Text = Strings.SELECT_TO_BREW
	brewPreviewLabel.Font = FONT_BODY
	brewPreviewLabel.TextSize = 15
	brewPreviewLabel.TextColor3 = Color3.fromRGB(150, 150, 170)
	brewPreviewLabel.BackgroundTransparency = 1
	brewPreviewLabel.Size = UDim2.new(1, 0, 0, 26)
	brewPreviewLabel.Position = UDim2.new(0, 0, 1, -72)
	brewPreviewLabel.TextXAlignment = Enum.TextXAlignment.Center
	brewPreviewLabel.ZIndex = 12
	brewPreviewLabel.Parent = brewPanel

	-- Brew button
	brewButton = createButton("BrewButton", Strings.BREW, UDim2.new(1, 0, 0, 38), brewPanel)
	brewButton.Position = UDim2.new(0, 0, 1, -42)
	brewButton.Font = FONT_HEADER
	brewButton.TextSize = 18
	brewButton.ZIndex = 12

	brewButton.Activated:Connect(function()
		if #selectedIngredients == 2 then
			fireRemote(Network.BrewPotion, selectedIngredients[1], selectedIngredients[2])
			UIController.closePanels()
		end
	end)
end

---------------------------------------------------------------------------
-- Sell Panel (opens when clicking sell station)
---------------------------------------------------------------------------

local sellScrollFrame: ScrollingFrame = nil :: any
local sellAllButton: TextButton = nil :: any

local function populateSellList()
	local scroll = sellScrollFrame
	if not scroll then return end

	-- Clear existing entries
	for _, child in scroll:GetChildren() do
		if child:IsA("Frame") or child:IsA("TextLabel") then
			child:Destroy()
		end
	end

	local potions = playerState.Potions
	if not potions or #potions == 0 then
		local emptyLabel = Instance.new("TextLabel")
		emptyLabel.Name = "EmptyLabel"
		emptyLabel.Text = Strings.NO_POTIONS
		emptyLabel.Font = FONT_BODY
		emptyLabel.TextSize = 16
		emptyLabel.TextColor3 = Color3.fromRGB(150, 150, 170)
		emptyLabel.BackgroundTransparency = 1
		emptyLabel.Size = UDim2.new(1, 0, 0, 30)
		emptyLabel.ZIndex = 12
		emptyLabel.Parent = scroll

		if sellAllButton then
			sellAllButton.Visible = false
		end
		return
	end

	if sellAllButton then
		sellAllButton.Visible = true
	end

	for i, potion in potions do
		local row = Instance.new("Frame")
		row.Name = "Potion_" .. i
		row.Size = UDim2.new(1, 0, 0, 44)
		row.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
		row.BackgroundTransparency = 0.3
		row.BorderSizePixel = 0
		row.LayoutOrder = i
		row.ZIndex = 12
		row.Parent = scroll

		local rowCorner = Instance.new("UICorner")
		rowCorner.CornerRadius = UDim.new(0, 6)
		rowCorner.Parent = row

		-- Potion name
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "Name"
		nameLabel.Text = potion.DisplayName or potion.Id
		nameLabel.Font = FONT_BODY
		nameLabel.TextSize = 15
		nameLabel.TextColor3 = TEXT_COLOR
		nameLabel.BackgroundTransparency = 1
		nameLabel.Size = UDim2.new(0.4, -8, 1, 0)
		nameLabel.Position = UDim2.new(0, 8, 0, 0)
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.ZIndex = 13
		nameLabel.Parent = row

		-- Value
		local valueLabel = Instance.new("TextLabel")
		valueLabel.Name = "Value"
		valueLabel.Text = tostring(potion.Value) .. " Essence"
		valueLabel.Font = FONT_BODY
		valueLabel.TextSize = 15
		valueLabel.TextColor3 = GOLD_TEXT_COLOR
		valueLabel.BackgroundTransparency = 1
		valueLabel.Size = UDim2.new(0.25, 0, 1, 0)
		valueLabel.Position = UDim2.new(0.4, 0, 0, 0)
		valueLabel.TextXAlignment = Enum.TextXAlignment.Center
		valueLabel.ZIndex = 13
		valueLabel.Parent = row

		-- Sell button
		local sellBtn = createButton("SellBtn", Strings.SELL, UDim2.new(0, 70, 0, 30), row)
		sellBtn.Position = UDim2.new(1, -78, 0.5, -15)
		sellBtn.ZIndex = 14

		sellBtn.Activated:Connect(function()
			if soundController then soundController.onSell() end
			fireRemote(Network.SellPotion, i)
			UIController.closePanels()
		end)
	end
end

local function createSellPanel()
	sellPanel = createPanel("SellPanel", UDim2.new(0, 360, 0, 400), UDim2.new(0.5, 0, 0.5, 0))
	sellPanel.Parent = screenGui

	-- Title
	local title = createLabel("Title", "Sell Potions", FONT_HEADER, 22, sellPanel)
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.Size = UDim2.new(1, -40, 0, 30)

	createCloseButton(sellPanel)

	-- Scrolling potion list
	sellScrollFrame = createScrollingList(
		"PotionScroll",
		UDim2.new(1, 0, 1, -100),
		UDim2.new(0, 0, 0, 40),
		sellPanel
	)

	-- Sell All button
	sellAllButton = createButton("SellAllButton", Strings.SELL_ALL, UDim2.new(1, 0, 0, 38), sellPanel)
	sellAllButton.Position = UDim2.new(0, 0, 1, -42)
	sellAllButton.Font = FONT_HEADER
	sellAllButton.TextSize = 18
	sellAllButton.BackgroundColor3 = Color3.fromRGB(60, 160, 60)
	sellAllButton.ZIndex = 12

	sellAllButton.MouseEnter:Connect(function()
		sellAllButton.BackgroundColor3 = Color3.fromRGB(80, 180, 80)
	end)
	sellAllButton.MouseLeave:Connect(function()
		sellAllButton.BackgroundColor3 = Color3.fromRGB(60, 160, 60)
	end)

	sellAllButton.Activated:Connect(function()
		local potions = playerState.Potions
		if potions and #potions > 0 then
			if soundController then soundController.onSell() end
			-- Single server call instead of N individual sells
			fireRemote(Network.SellAll)
		end
		UIController.closePanels()
	end)
end

---------------------------------------------------------------------------
-- Upgrade Panel (opens when clicking shop/upgrade station in world)
---------------------------------------------------------------------------

local upgradeLabBtn: TextButton = nil :: any
local upgradeCauldronBtn: TextButton = nil :: any
local upgradeLabInfo: TextLabel = nil :: any
local upgradeCauldronInfo: TextLabel = nil :: any

local function updateUpgradeButtons()
	local labLevel = playerState.LabLevel or 1
	local cauldronLevel = playerState.CauldronLevel or 1

	-- Lab upgrade
	if labLevel < Config.MAX_LAB_LEVEL then
		local nextLab = Config.LAB_LEVELS[labLevel + 1]
		if nextLab and upgradeLabBtn then
			upgradeLabBtn.Text = Strings.UPGRADE_LAB .. " (" .. nextLab.cost .. " E)"
			upgradeLabBtn.Visible = true
		end
		if upgradeLabInfo and nextLab then
			local currentLab = Config.LAB_LEVELS[labLevel]
			local extraPlots = nextLab.plots - (currentLab and currentLab.plots or 0)
			upgradeLabInfo.Text = formatString(Strings.UPGRADE_LAB_INFO, {
				plots = extraPlots,
				name = nextLab.name,
			})
		end
	else
		if upgradeLabBtn then
			upgradeLabBtn.Visible = false
		end
		if upgradeLabInfo then
			upgradeLabInfo.Text = Strings.MAX_LAB_LEVEL
		end
	end

	-- Cauldron upgrade
	if cauldronLevel < Config.MAX_CAULDRON_LEVEL then
		local nextCauldron = Config.CAULDRON_LEVELS[cauldronLevel + 1]
		if nextCauldron and upgradeCauldronBtn then
			upgradeCauldronBtn.Text = Strings.UPGRADE_CAULDRON .. " (" .. nextCauldron.cost .. " E)"
			upgradeCauldronBtn.Visible = true
		end
		if upgradeCauldronInfo and nextCauldron then
			upgradeCauldronInfo.Text = formatString(Strings.UPGRADE_CAULDRON_INFO, {
				time = nextCauldron.brewTime,
				bonus = math.floor((nextCauldron.valueBonus - 1) * 100),
				name = nextCauldron.name,
			})
		end
	else
		if upgradeCauldronBtn then
			upgradeCauldronBtn.Visible = false
		end
		if upgradeCauldronInfo then
			upgradeCauldronInfo.Text = Strings.MAX_CAULDRON_LEVEL
		end
	end
end

local function createUpgradePanel()
	upgradePanel = createPanel("UpgradePanel", UDim2.new(0, 340, 0, 260), UDim2.new(0.5, 0, 0.5, 0))
	upgradePanel.Parent = screenGui

	-- Title
	local title = createLabel("Title", "Upgrades", FONT_HEADER, 22, upgradePanel)
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.Size = UDim2.new(1, -40, 0, 30)

	createCloseButton(upgradePanel)

	-- Lab upgrade section
	local labSection = Instance.new("Frame")
	labSection.Name = "LabSection"
	labSection.Size = UDim2.new(1, 0, 0, 76)
	labSection.Position = UDim2.new(0, 0, 0, 44)
	labSection.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
	labSection.BackgroundTransparency = 0.3
	labSection.BorderSizePixel = 0
	labSection.ZIndex = 11
	labSection.Parent = upgradePanel

	local labCorner = Instance.new("UICorner")
	labCorner.CornerRadius = UDim.new(0, 6)
	labCorner.Parent = labSection

	upgradeLabInfo = Instance.new("TextLabel")
	upgradeLabInfo.Name = "LabInfo"
	upgradeLabInfo.Text = ""
	upgradeLabInfo.Font = FONT_BODY
	upgradeLabInfo.TextSize = 14
	upgradeLabInfo.TextColor3 = Color3.fromRGB(180, 180, 200)
	upgradeLabInfo.BackgroundTransparency = 1
	upgradeLabInfo.Size = UDim2.new(1, -16, 0, 22)
	upgradeLabInfo.Position = UDim2.new(0, 8, 0, 6)
	upgradeLabInfo.TextXAlignment = Enum.TextXAlignment.Left
	upgradeLabInfo.ZIndex = 12
	upgradeLabInfo.Parent = labSection

	upgradeLabBtn = createButton("UpgradeLabBtn", Strings.UPGRADE_LAB, UDim2.new(1, -16, 0, 34), labSection)
	upgradeLabBtn.Position = UDim2.new(0, 8, 0, 34)
	upgradeLabBtn.ZIndex = 13

	upgradeLabBtn.Activated:Connect(function()
		if soundController then soundController.onUpgrade() end
		fireRemote(Network.UpgradeLab)
	end)

	-- Cauldron upgrade section
	local cauldronSection = Instance.new("Frame")
	cauldronSection.Name = "CauldronSection"
	cauldronSection.Size = UDim2.new(1, 0, 0, 76)
	cauldronSection.Position = UDim2.new(0, 0, 0, 132)
	cauldronSection.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
	cauldronSection.BackgroundTransparency = 0.3
	cauldronSection.BorderSizePixel = 0
	cauldronSection.ZIndex = 11
	cauldronSection.Parent = upgradePanel

	local cauldronCorner = Instance.new("UICorner")
	cauldronCorner.CornerRadius = UDim.new(0, 6)
	cauldronCorner.Parent = cauldronSection

	upgradeCauldronInfo = Instance.new("TextLabel")
	upgradeCauldronInfo.Name = "CauldronInfo"
	upgradeCauldronInfo.Text = ""
	upgradeCauldronInfo.Font = FONT_BODY
	upgradeCauldronInfo.TextSize = 14
	upgradeCauldronInfo.TextColor3 = Color3.fromRGB(180, 180, 200)
	upgradeCauldronInfo.BackgroundTransparency = 1
	upgradeCauldronInfo.Size = UDim2.new(1, -16, 0, 22)
	upgradeCauldronInfo.Position = UDim2.new(0, 8, 0, 6)
	upgradeCauldronInfo.TextXAlignment = Enum.TextXAlignment.Left
	upgradeCauldronInfo.ZIndex = 12
	upgradeCauldronInfo.Parent = cauldronSection

	upgradeCauldronBtn = createButton("UpgradeCauldronBtn", Strings.UPGRADE_CAULDRON, UDim2.new(1, -16, 0, 34), cauldronSection)
	upgradeCauldronBtn.Position = UDim2.new(0, 8, 0, 34)
	upgradeCauldronBtn.ZIndex = 13

	upgradeCauldronBtn.Activated:Connect(function()
		if soundController then soundController.onUpgrade() end
		fireRemote(Network.UpgradeCauldron)
	end)
end

---------------------------------------------------------------------------
-- Journal Panel (opens from HUD button)
-- Tabs: How to Play | Ingredients | Recipes | Odds | Fun Facts
---------------------------------------------------------------------------

local journalTabButtons: { [string]: TextButton } = {}
local journalContentFrame: Frame = nil :: any
local activeJournalTab: string = "basics"

local function clearJournalContent()
	if not journalContentFrame then return end
	for _, child in journalContentFrame:GetChildren() do
		child:Destroy()
	end
end

local function makeJournalText(text: string, size: number, parent: GuiObject, italic: boolean?): TextLabel
	local label = Instance.new("TextLabel")
	label.Text = text
	label.Font = if italic then FONT_BODY else FONT_BODY
	label.TextSize = size
	label.TextColor3 = TEXT_COLOR
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 0, 0)
	label.AutomaticSize = Enum.AutomaticSize.Y
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.ZIndex = 22
	label.Parent = parent
	return label
end

local function makeJournalDivider(parent: GuiObject)
	local line = Instance.new("Frame")
	line.Size = UDim2.new(1, 0, 0, 1)
	line.BackgroundColor3 = PANEL_STROKE_COLOR
	line.BackgroundTransparency = 0.6
	line.BorderSizePixel = 0
	line.ZIndex = 22
	line.Parent = parent
end

local function showJournalBasics()
	clearJournalContent()
	makeJournalText(Strings.JOURNAL_WELCOME, 15, journalContentFrame)
	makeJournalDivider(journalContentFrame)
	for _, line in Journal.HowToPlay do
		local bullet = makeJournalText("• " .. line, 14, journalContentFrame)
		bullet.TextColor3 = Color3.fromRGB(200, 220, 255)
	end
end

local function showJournalIngredients()
	clearJournalContent()
	local ingredientList = Ingredients.getList()
	for _, entry in ingredientList do
		local def = entry.def
		local block = Instance.new("Frame")
		block.Size = UDim2.new(1, 0, 0, 0)
		block.AutomaticSize = Enum.AutomaticSize.Y
		block.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
		block.BackgroundTransparency = 0.3
		block.BorderSizePixel = 0
		block.ZIndex = 22
		block.Parent = journalContentFrame

		local bCorner = Instance.new("UICorner")
		bCorner.CornerRadius = UDim.new(0, 6)
		bCorner.Parent = block

		local bPad = Instance.new("UIPadding")
		bPad.PaddingTop = UDim.new(0, 6)
		bPad.PaddingBottom = UDim.new(0, 6)
		bPad.PaddingLeft = UDim.new(0, 8)
		bPad.PaddingRight = UDim.new(0, 8)
		bPad.Parent = block

		local bList = Instance.new("UIListLayout")
		bList.SortOrder = Enum.SortOrder.LayoutOrder
		bList.Padding = UDim.new(0, 3)
		bList.Parent = block

		local header = makeJournalText(def.displayName, 16, block)
		header.Font = FONT_HEADER
		header.TextColor3 = def.color
		header.LayoutOrder = 1

		local desc = makeJournalText(def.description, 13, block)
		desc.TextColor3 = Color3.fromRGB(180, 180, 200)
		desc.LayoutOrder = 2

		local hook = makeJournalText(def.scienceHook, 13, block)
		hook.TextColor3 = Color3.fromRGB(140, 220, 180)
		hook.LayoutOrder = 3

		local note = Journal.IngredientNotes[entry.id]
		if note then
			local noteLabel = makeJournalText(note, 12, block)
			noteLabel.TextColor3 = Color3.fromRGB(160, 190, 255)
			noteLabel.LayoutOrder = 4
		end
	end
end

local function showJournalRecipes()
	clearJournalContent()
	-- Show discovered recipes with science hooks
	local discoveredSet = playerState.DiscoveredRecipes or {}
	local totalDiscovered = 0
	for _ in discoveredSet do totalDiscovered += 1 end

	local totalRecipes = 0
	for _ in Recipes.Map do totalRecipes += 1 end

	local progress = makeJournalText("Recipes discovered: " .. totalDiscovered .. " / " .. totalRecipes, 15, journalContentFrame)
	progress.Font = FONT_HEADER
	progress.TextColor3 = GOLD_TEXT_COLOR
	makeJournalDivider(journalContentFrame)

	for key, recipe in Recipes.Map do
		local isKnown = discoveredSet[recipe.id] == true

		local block = Instance.new("Frame")
		block.Size = UDim2.new(1, 0, 0, 0)
		block.AutomaticSize = Enum.AutomaticSize.Y
		block.BackgroundColor3 = if isKnown then Color3.fromRGB(30, 45, 30) else Color3.fromRGB(40, 40, 50)
		block.BackgroundTransparency = 0.3
		block.BorderSizePixel = 0
		block.ZIndex = 22
		block.Parent = journalContentFrame

		local bCorner = Instance.new("UICorner")
		bCorner.CornerRadius = UDim.new(0, 6)
		bCorner.Parent = block

		local bPad = Instance.new("UIPadding")
		bPad.PaddingTop = UDim.new(0, 6)
		bPad.PaddingBottom = UDim.new(0, 6)
		bPad.PaddingLeft = UDim.new(0, 8)
		bPad.PaddingRight = UDim.new(0, 8)
		bPad.Parent = block

		local bList = Instance.new("UIListLayout")
		bList.SortOrder = Enum.SortOrder.LayoutOrder
		bList.Padding = UDim.new(0, 3)
		bList.Parent = block

		if isKnown then
			local header = makeJournalText(recipe.displayName .. " (Discovered!)", 15, block)
			header.Font = FONT_HEADER
			header.TextColor3 = recipe.color
			header.LayoutOrder = 1

			if recipe.scienceHook then
				local hook = makeJournalText(recipe.scienceHook, 13, block)
				hook.TextColor3 = Color3.fromRGB(140, 220, 180)
				hook.LayoutOrder = 2
			end

			local fullNote = Journal.RecipeNotes[recipe.id]
			if fullNote then
				local noteLabel = makeJournalText(fullNote, 12, block)
				noteLabel.TextColor3 = Color3.fromRGB(160, 190, 255)
				noteLabel.LayoutOrder = 3
			end
		else
			local unknown = makeJournalText("??? (Brew it to discover!)", 14, block)
			unknown.TextColor3 = Color3.fromRGB(120, 120, 140)
			unknown.LayoutOrder = 1

			local hint = makeJournalText("Hint: combine two different ingredients to find this.", 12, block)
			hint.TextColor3 = Color3.fromRGB(100, 100, 120)
			hint.LayoutOrder = 2
		end
	end
end

local function showJournalOdds()
	clearJournalContent()
	makeJournalText(Strings.JOURNAL_ODDS_HEADER, 15, journalContentFrame).Font = FONT_HEADER
	makeJournalText(Strings.JOURNAL_ODDS_NOTE, 13, journalContentFrame).TextColor3 = Color3.fromRGB(170, 200, 170)
	makeJournalDivider(journalContentFrame)

	local oddsLines = {
		{ text = Strings.ODDS_LEGENDARY, color = Config.MUTATION_TIERS[5].color },
		{ text = Strings.ODDS_EPIC,      color = Config.MUTATION_TIERS[4].color },
		{ text = Strings.ODDS_RARE,      color = Config.MUTATION_TIERS[3].color },
		{ text = Strings.ODDS_UNCOMMON,  color = Config.MUTATION_TIERS[2].color },
		{ text = Strings.ODDS_COMMON,    color = Config.MUTATION_TIERS[1].color },
	}
	for _, entry in oddsLines do
		local label = makeJournalText(entry.text, 14, journalContentFrame)
		label.Font = Enum.Font.Code
		label.TextColor3 = entry.color
	end

	makeJournalDivider(journalContentFrame)
	makeJournalText("Value formula: base × rarity1 × rarity2 × cauldron bonus", 13, journalContentFrame).TextColor3 = Color3.fromRGB(180, 180, 200)
	makeJournalText("Example: Celestial Brew with two Legendary Starblooms in a Silver Cauldron = 75 × 50 × 50 × 1.25 = 234,375 Essence!", 13, journalContentFrame).TextColor3 = GOLD_TEXT_COLOR

	makeJournalDivider(journalContentFrame)

	-- Rarity science notes
	for _, tier in Config.MUTATION_TIERS do
		local note = Journal.RarityNotes[tier.name]
		if note then
			local label = makeJournalText(tier.name .. ": " .. note, 13, journalContentFrame)
			label.TextColor3 = tier.color
		end
	end
end

local function showJournalFunFacts()
	clearJournalContent()
	makeJournalText(Strings.JOURNAL_FACTS_HEADER, 16, journalContentFrame).Font = FONT_HEADER
	makeJournalDivider(journalContentFrame)
	for i, fact in Journal.FunFacts do
		local label = makeJournalText(tostring(i) .. ". " .. fact, 14, journalContentFrame)
		label.TextColor3 = Color3.fromRGB(180, 230, 200)
	end
end

local journalTabFunctions: { [string]: () -> () } = {
	basics      = showJournalBasics,
	ingredients = showJournalIngredients,
	recipes     = showJournalRecipes,
	odds        = showJournalOdds,
	facts       = showJournalFunFacts,
}

local function switchJournalTab(tabName: string)
	activeJournalTab = tabName

	-- Update tab button visuals
	for name, btn in journalTabButtons do
		if name == tabName then
			btn.BackgroundColor3 = PANEL_STROKE_COLOR
			btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		else
			btn.BackgroundColor3 = BUTTON_COLOR
			btn.TextColor3 = TEXT_COLOR
		end
	end

	-- Show content
	local fn = journalTabFunctions[tabName]
	if fn then
		fn()
	end
end

local function createJournalPanel()
	journalPanel = createPanel("JournalPanel", UDim2.new(0, 520, 0, 560), UDim2.new(0.5, 0, 0.5, 0))
	journalPanel.Parent = screenGui

	-- Title
	local title = createLabel("Title", Strings.JOURNAL, FONT_HEADER, 20, journalPanel)
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.Size = UDim2.new(1, -40, 0, 28)

	createCloseButton(journalPanel)

	-- Tab bar
	local tabBar = Instance.new("Frame")
	tabBar.Name = "TabBar"
	tabBar.Size = UDim2.new(1, 0, 0, 32)
	tabBar.Position = UDim2.new(0, 0, 0, 34)
	tabBar.BackgroundTransparency = 1
	tabBar.ZIndex = 11
	tabBar.Parent = journalPanel

	local tabLayout = Instance.new("UIListLayout")
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
	tabLayout.Padding = UDim.new(0, 4)
	tabLayout.Parent = tabBar

	local tabs = {
		{ id = "basics",      label = Strings.TAB_BASICS,      order = 1 },
		{ id = "ingredients", label = Strings.TAB_INGREDIENTS,  order = 2 },
		{ id = "recipes",     label = Strings.TAB_RECIPES,      order = 3 },
		{ id = "odds",        label = Strings.TAB_ODDS,         order = 4 },
		{ id = "facts",       label = Strings.TAB_FUN_FACTS,    order = 5 },
	}

	for _, tab in tabs do
		local btn = createButton(tab.id, tab.label, UDim2.new(0, 90, 1, 0), tabBar)
		btn.TextSize = 12
		btn.LayoutOrder = tab.order
		btn.ZIndex = 12
		journalTabButtons[tab.id] = btn

		btn.Activated:Connect(function()
			switchJournalTab(tab.id)
		end)
	end

	-- Content scroll area
	local scroll = createScrollingList(
		"JournalContent",
		UDim2.new(1, 0, 1, -78),
		UDim2.new(0, 0, 0, 74),
		journalPanel
	)
	scroll.ZIndex = 21

	-- Override scroll's UIListLayout padding for more spacing
	local scrollLayout = scroll:FindFirstChildWhichIsA("UIListLayout")
	if scrollLayout then
		scrollLayout.Padding = UDim.new(0, 8)
	end

	journalContentFrame = scroll
end

---------------------------------------------------------------------------
-- Settings Panel (volume / accessibility controls)
---------------------------------------------------------------------------

--- Build one volume row: label on left, [−] [N%] [+] on right.
--- Returns the current-value TextLabel so the caller can update it.
local function createVolumeRow(
	parent: Frame,
	rowName: string,
	labelText: string,
	yOffset: number,
	initialPct: number,
	onChanged: (newPct: number) -> ()
): TextLabel
	local row = Instance.new("Frame")
	row.Name = rowName
	row.Size = UDim2.new(1, 0, 0, 36)
	row.Position = UDim2.new(0, 0, 0, yOffset)
	row.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
	row.BackgroundTransparency = 0.3
	row.BorderSizePixel = 0
	row.ZIndex = 11
	row.Parent = parent

	local rowCorner = Instance.new("UICorner")
	rowCorner.CornerRadius = UDim.new(0, 6)
	rowCorner.Parent = row

	-- Left label
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.4, 0, 1, 0)
	nameLabel.Position = UDim2.new(0, 8, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = FONT_BODY
	nameLabel.TextSize = 15
	nameLabel.TextColor3 = TEXT_COLOR
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Text = labelText
	nameLabel.ZIndex = 12
	nameLabel.Parent = row

	-- Current value label (centre)
	local valueLabel = Instance.new("TextLabel")
	valueLabel.Name = "Value"
	valueLabel.Size = UDim2.new(0.2, 0, 1, 0)
	valueLabel.Position = UDim2.new(0.4, 0, 0, 0)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Font = FONT_HEADER
	valueLabel.TextSize = 15
	valueLabel.TextColor3 = GOLD_TEXT_COLOR
	valueLabel.TextXAlignment = Enum.TextXAlignment.Center
	valueLabel.Text = tostring(initialPct) .. "%"
	valueLabel.ZIndex = 12
	valueLabel.Parent = row

	-- Decrease button
	local minusBtn = createButton("MinusBtn", "−", UDim2.new(0, 30, 0, 26), row)
	minusBtn.Position = UDim2.new(0.6, 0, 0.5, -13)
	minusBtn.TextSize = 18
	minusBtn.ZIndex = 13

	-- Increase button
	local plusBtn = createButton("PlusBtn", "+", UDim2.new(0, 30, 0, 26), row)
	plusBtn.Position = UDim2.new(0.6, 36, 0.5, -13)
	plusBtn.TextSize = 18
	plusBtn.ZIndex = 13

	local currentPct = initialPct

	minusBtn.Activated:Connect(function()
		currentPct = math.max(0, currentPct - 10)
		valueLabel.Text = tostring(currentPct) .. "%"
		onChanged(currentPct)
	end)

	plusBtn.Activated:Connect(function()
		currentPct = math.min(100, currentPct + 10)
		valueLabel.Text = tostring(currentPct) .. "%"
		onChanged(currentPct)
	end)

	return valueLabel
end

local function createSettingsPanel()
	settingsPanel = createPanel("SettingsPanel", UDim2.new(0, 320, 0, 260), UDim2.new(0.5, 0, 0.5, 0))
	settingsPanel.Parent = screenGui

	local title = createLabel("Title", "⚙ Settings", FONT_HEADER, 20, settingsPanel)
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.Size = UDim2.new(1, -40, 0, 28)

	createCloseButton(settingsPanel)

	-- Subtitle
	local sub = createLabel("Sub", "Audio", FONT_BODY, 13, settingsPanel)
	sub.Position = UDim2.new(0, 0, 0, 34)
	sub.TextColor3 = Color3.fromRGB(150, 150, 180)

	-- Music volume row
	settingsMusicLabel = createVolumeRow(
		settingsPanel, "MusicRow", "Music", 56, musicVolumePct,
		function(pct: number)
			musicVolumePct = pct
			if soundController then
				soundController.setMusicVolume(pct / 100)
			end
		end
	)

	-- SFX volume row
	settingsSFXLabel = createVolumeRow(
		settingsPanel, "SFXRow", "Sound FX", 100, sfxVolumePct,
		function(pct: number)
			sfxVolumePct = pct
			if soundController then
				soundController.setSFXVolume(pct / 100)
			end
		end
	)

	-- Mute all toggle
	local muteBtn = createButton("MuteBtn", Strings.MUTE_ALL, UDim2.new(1, 0, 0, 32), settingsPanel)
	muteBtn.Position = UDim2.new(0, 0, 0, 148)
	muteBtn.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
	muteBtn.ZIndex = 12

	muteBtn.MouseEnter:Connect(function()
		muteBtn.BackgroundColor3 = Color3.fromRGB(150, 60, 60)
	end)
	muteBtn.MouseLeave:Connect(function()
		muteBtn.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
	end)

	local muted = false
	muteBtn.Activated:Connect(function()
		muted = not muted
		if soundController then
			soundController.setMuted(muted)
		end
		muteBtn.Text = if muted then "Unmute All" else "Mute All"
		muteBtn.BackgroundColor3 = if muted
			then Color3.fromRGB(40, 100, 40)
			else Color3.fromRGB(120, 40, 40)
	end)

	-- Performance Mode toggle — disables bloom, atmosphere, and particles
	-- on low-end devices. Wired to LightingController + ParticleController
	-- injected via UIController.setPerformanceControllers().
	local perfBtn = createButton("PerfModeBtn", Strings.PERF_MODE_OFF, UDim2.new(1, 0, 0, 32), settingsPanel)
	perfBtn.Position = UDim2.new(0, 0, 0, 190)
	perfBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
	perfBtn.ZIndex = 12

	perfBtn.MouseEnter:Connect(function()
		perfBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 90)
	end)
	perfBtn.MouseLeave:Connect(function()
		local isOn = perfBtn.Text == "Performance Mode: ON"
		perfBtn.BackgroundColor3 = if isOn
			then Color3.fromRGB(40, 80, 40)
			else Color3.fromRGB(50, 50, 70)
	end)

	local perfOn = false
	perfBtn.Activated:Connect(function()
		perfOn = not perfOn
		if perfOn then
			if lightingController then lightingController.disableEffects() end
			if particleController then particleController.disableAll() end
			perfBtn.Text = Strings.PERF_MODE_ON
			perfBtn.BackgroundColor3 = Color3.fromRGB(40, 80, 40)
		else
			if lightingController then lightingController.init() end
			if particleController then particleController.enableAll() end
			perfBtn.Text = Strings.PERF_MODE_OFF
			perfBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
		end
	end)
end

---------------------------------------------------------------------------
-- Cosmetic Shop Panel
-- Three category tabs: Lab Themes | Cauldron Tints | Harvest Particles.
-- Each item row shows the name, price badge, and an Equip / Buy button.
-- Purchasing triggers MarketplaceService:PromptProductPurchase on the
-- client; ProcessReceipt on the server grants ownership and syncs state.
---------------------------------------------------------------------------

local activeCosmeticTab = "LabTheme"
local cosmeticListFrame: ScrollingFrame = nil :: any

local CATEGORY_TABS: { { id: string, label: string } } = {
	{ id = "LabTheme",         label = "Lab Themes" },
	{ id = "CauldronTint",     label = "Cauldron" },
	{ id = "HarvestParticles", label = "Harvest FX" },
}

local function populateCosmeticList(category: string)
	if not cosmeticListFrame then return end

	-- Clear existing rows
	for _, child in cosmeticListFrame:GetChildren() do
		if child:IsA("Frame") or child:IsA("TextButton") then
			child:Destroy()
		end
	end

	local items = Cosmetics.getCategory(category)
	local owned  = playerState.OwnedCosmetics or {}
	local active = playerState.ActiveCosmetic  or {}

	local yOffset = 0
	for _, def in items do
		local row = Instance.new("Frame")
		row.Name = def.id
		row.Size = UDim2.new(1, -8, 0, 64)
		row.Position = UDim2.new(0, 4, 0, yOffset)
		row.BackgroundColor3 = Color3.fromRGB(40, 35, 60)
		row.BackgroundTransparency = 0.3
		row.BorderSizePixel = 0
		row.Parent = cosmeticListFrame

		local rowCorner = Instance.new("UICorner")
		rowCorner.CornerRadius = CORNER_RADIUS
		rowCorner.Parent = row

		-- Name label
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Text = def.name
		nameLabel.Font = FONT_HEADER
		nameLabel.TextSize = 14
		nameLabel.TextColor3 = TEXT_COLOR
		nameLabel.BackgroundTransparency = 1
		nameLabel.Position = UDim2.new(0, 8, 0, 6)
		nameLabel.Size = UDim2.new(1, -110, 0, 18)
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = row

		-- Description label
		local descLabel = Instance.new("TextLabel")
		descLabel.Text = def.description
		descLabel.Font = FONT_BODY
		descLabel.TextSize = 11
		descLabel.TextColor3 = Color3.fromRGB(170, 160, 200)
		descLabel.BackgroundTransparency = 1
		descLabel.Position = UDim2.new(0, 8, 0, 26)
		descLabel.Size = UDim2.new(1, -110, 0, 30)
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.TextWrapped = true
		descLabel.Parent = row

		-- Action button (right side)
		local isOwned   = (def.price == 0) or (owned[def.id] == true)
		local isActive  = (active[def.category] == def.id)

		local btnText: string
		local btnColor: Color3

		if isActive then
			btnText  = "Equipped"
			btnColor = Color3.fromRGB(30, 90, 30)
		elseif isOwned then
			btnText  = "Equip"
			btnColor = Color3.fromRGB(50, 70, 140)
		else
			btnText  = def.price .. " R"
			btnColor = Color3.fromRGB(120, 50, 20)
		end

		local actionBtn = createButton("ActionBtn", btnText, UDim2.new(0, 88, 0, 32), row)
		actionBtn.Position = UDim2.new(1, -96, 0, 16)
		actionBtn.TextSize = 13
		actionBtn.BackgroundColor3 = btnColor

		if isActive then
			actionBtn.Active = false
		elseif isOwned then
			actionBtn.Activated:Connect(function()
				if remotes then
					remotes:FindFirstChild(Network.EquipCosmetic):FireServer(def.id)
				end
			end)
		else
			-- Trigger Roblox purchase prompt (cosmetics are Developer Products)
			actionBtn.Activated:Connect(function()
				if def.productId ~= 0 then
					MarketplaceService:PromptProductPurchase(Players.LocalPlayer, def.productId)
				end
			end)
		end

		yOffset += 72
	end

	cosmeticListFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset)
end

local function createCosmeticPanel()
	cosmeticPanel = createPanel("CosmeticPanel", UDim2.new(0, 480, 0, 440), UDim2.new(0.5, 0, 0.5, 0))
	cosmeticPanel.Parent = screenGui

	createLabel("Title", "Cosmetic Shop", FONT_HEADER, 20, cosmeticPanel)
	createCloseButton(cosmeticPanel)

	-- Game pass section header
	local passHint = createLabel(
		"PassHint",
		"Game Passes: Speed Brew | Auto-Harvest | VIP — available on the game page.",
		FONT_BODY, 11, cosmeticPanel
	)
	passHint.Position = UDim2.new(0, 0, 0, 28)
	passHint.TextColor3 = Color3.fromRGB(200, 180, 120)
	passHint.Size = UDim2.new(1, 0, 0, 24)

	-- Category tab buttons
	local tabY = 56
	local tabWidth = 140
	for i, tab in CATEGORY_TABS do
		local tabBtn = createButton(
			"Tab_" .. tab.id,
			tab.label,
			UDim2.new(0, tabWidth, 0, 28),
			cosmeticPanel
		)
		tabBtn.Position = UDim2.new(0, (i - 1) * (tabWidth + 4), 0, tabY)
		tabBtn.TextSize = 13
		tabBtn.BackgroundColor3 = Color3.fromRGB(55, 45, 80)
		tabBtn.ZIndex = 12

		tabBtn.Activated:Connect(function()
			activeCosmeticTab = tab.id
			populateCosmeticList(activeCosmeticTab)
		end)
	end

	-- Refund notice (legal compliance — CARU/FTC)
	local refundNotice = createLabel(
		"RefundNotice",
		Strings.REFUND_NOTICE,
		FONT_BODY, 10, cosmeticPanel
	)
	refundNotice.Position = UDim2.new(0, 0, 1, -18)
	refundNotice.Size = UDim2.new(1, 0, 0, 16)
	refundNotice.TextColor3 = Color3.fromRGB(140, 130, 160)
	refundNotice.ZIndex = 12

	-- Scrolling item list
	cosmeticListFrame = createScrollingList(
		"CosmeticList",
		UDim2.new(1, 0, 1, -114),
		UDim2.new(0, 0, 0, 92),
		cosmeticPanel
	)
	cosmeticListFrame.ZIndex = 11
end

---------------------------------------------------------------------------
-- Notification System
---------------------------------------------------------------------------

local notificationCount = 0

local function createNotificationContainer()
	notificationContainer = Instance.new("Frame")
	notificationContainer.Name = "NotificationContainer"
	notificationContainer.Size = UDim2.new(0, 300, 1, -20)
	notificationContainer.Position = UDim2.new(1, -310, 0, 10)
	notificationContainer.BackgroundTransparency = 1
	notificationContainer.ZIndex = 20
	notificationContainer.Parent = screenGui

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.VerticalAlignment = Enum.VerticalAlignment.Top
	layout.Padding = UDim.new(0, 6)
	layout.Parent = notificationContainer
end

---------------------------------------------------------------------------
-- Leaderboard sidebar (always visible, top-right corner)
---------------------------------------------------------------------------

local TOP_N_DISPLAY = 10

local function createLeaderboardPanel()
	leaderboardPanel = Instance.new("Frame")
	leaderboardPanel.Name = "Leaderboard"
	leaderboardPanel.Size = UDim2.new(0, 210, 0, 26 + TOP_N_DISPLAY * 22 + 8)
	leaderboardPanel.Position = UDim2.new(1, -220, 0, 10)
	leaderboardPanel.AnchorPoint = Vector2.new(0, 0)
	leaderboardPanel.BackgroundColor3 = PANEL_BG_COLOR
	leaderboardPanel.BackgroundTransparency = PANEL_BG_TRANSPARENCY
	leaderboardPanel.BorderSizePixel = 0
	leaderboardPanel.ZIndex = 5
	leaderboardPanel.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = CORNER_RADIUS
	corner.Parent = leaderboardPanel

	local stroke = Instance.new("UIStroke")
	stroke.Color = PANEL_STROKE_COLOR
	stroke.Thickness = PANEL_STROKE_THICKNESS
	stroke.Parent = leaderboardPanel

	-- Title row
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -8, 0, 20)
	title.Position = UDim2.new(0, 4, 0, 4)
	title.BackgroundTransparency = 1
	title.Font = FONT_HEADER
	title.TextSize = 13
	title.TextColor3 = GOLD_TEXT_COLOR
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.Text = Strings.LEADERBOARD_TITLE
	title.ZIndex = 6
	title.Parent = leaderboardPanel

	-- Pre-create row labels (rank + name, score right-aligned)
	for i = 1, TOP_N_DISPLAY do
		local rowY = 26 + (i - 1) * 22

		local row = Instance.new("TextLabel")
		row.Name = "Row_" .. i
		row.Size = UDim2.new(1, -8, 0, 20)
		row.Position = UDim2.new(0, 4, 0, rowY)
		row.BackgroundTransparency = 1
		row.Font = FONT_BODY
		row.TextSize = 12
		row.TextColor3 = TEXT_COLOR
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.Text = i .. ". —"
		row.ZIndex = 6
		row.Parent = leaderboardPanel

		leaderboardRowLabels[i] = row
	end
end

---------------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------------

--- Creates all UI elements. Called once from Main.client.luau.
--- @param soundCtrl  Optional SoundController for UI action audio feedback.
function UIController.init(initialState: { [string]: any }, remotesFolder: Folder, soundCtrl: any?)
	playerState = initialState or {}
	remotes = remotesFolder
	soundController = soundCtrl

	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "AlchemyAcademyUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.IgnoreGuiInset = false
	screenGui.Parent = playerGui

	createHUD()
	createSeedPanel()
	createBrewPanel()
	createSellPanel()
	createUpgradePanel()
	createJournalPanel()
	createSettingsPanel()
	createCosmeticPanel()
	createLeaderboardPanel()
	createNotificationContainer()

	-- Refresh HUD with whatever state we already have
	UIController.updateState(playerState)
end

--- Refreshes ALL UI to match a new authoritative player state.
function UIController.updateState(newState: { [string]: any })
	if not newState then return end
	playerState = newState

	-- HUD
	if hudGoldLabel then
		hudGoldLabel.Text = Strings.GOLD .. ": " .. tostring(playerState.Essence or 0)
	end
	if hudLabLabel then
		local labLevel = playerState.LabLevel or 1
		local labDef = Config.LAB_LEVELS[labLevel]
		hudLabLabel.Text = formatString(Strings.HUD_LAB, {
			name = labDef and labDef.name or "Lv " .. labLevel,
			plots = labDef and labDef.plots or "?",
		})
	end
	if hudCauldronLabel then
		local cauldronLevel = playerState.CauldronLevel or 1
		local cauldronDef = Config.CAULDRON_LEVELS[cauldronLevel]
		hudCauldronLabel.Text = formatString(Strings.HUD_CAULDRON, {
			name = cauldronDef and cauldronDef.name or "Lv " .. cauldronLevel,
		})
	end

	-- Update upgrade panel if open
	updateUpgradeButtons()

	-- If brew panel is open, refresh ingredient list
	if brewPanel and brewPanel.Visible then
		populateBrewIngredients()
	end

	-- If sell panel is open, refresh potion list
	if sellPanel and sellPanel.Visible then
		populateSellList()
	end

	-- If journal is open on the recipes tab, refresh (discoveries may have updated)
	if journalPanel and journalPanel.Visible and activeJournalTab == "recipes" then
		showJournalRecipes()
	end

	-- If cosmetic panel is open, refresh (ownership may have updated after purchase)
	if cosmeticPanel and cosmeticPanel.Visible then
		populateCosmeticList(activeCosmeticTab)
	end
end

--- Displays a notification that slides in from the right and fades out.
function UIController.showNotification(message: string, color: Color3?)
	if not notificationContainer then return end

	notificationCount += 1
	local thisOrder = notificationCount

	local notifFrame = Instance.new("Frame")
	notifFrame.Name = "Notification_" .. thisOrder
	notifFrame.Size = UDim2.new(1, 0, 0, 36)
	notifFrame.BackgroundColor3 = PANEL_BG_COLOR
	notifFrame.BackgroundTransparency = 0.15
	notifFrame.BorderSizePixel = 0
	notifFrame.LayoutOrder = thisOrder
	notifFrame.ZIndex = 21
	-- Start offscreen to the right for slide-in
	notifFrame.Position = UDim2.new(1, 0, 0, 0)
	notifFrame.Parent = notificationContainer

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = notifFrame

	local stroke = Instance.new("UIStroke")
	stroke.Color = color or PANEL_STROKE_COLOR
	stroke.Thickness = 1
	stroke.Parent = notifFrame

	local label = Instance.new("TextLabel")
	label.Name = "Message"
	label.Text = message
	label.Font = FONT_BODY
	label.TextSize = 15
	label.TextColor3 = color or TEXT_COLOR
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, -12, 1, 0)
	label.Position = UDim2.new(0, 6, 0, 0)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.ZIndex = 22
	label.Parent = notifFrame

	-- Slide in
	local slideIn = TweenService:Create(
		notifFrame,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0, 0, 0, 0) }
	)
	slideIn:Play()

	-- After NOTIFICATION_DURATION seconds, fade out and destroy
	task.delay(Config.NOTIFICATION_DURATION, function()
		local fadeOut = TweenService:Create(
			notifFrame,
			TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ BackgroundTransparency = 1 }
		)
		local labelFade = TweenService:Create(
			label,
			TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ TextTransparency = 1 }
		)
		local strokeFade = TweenService:Create(
			stroke,
			TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Transparency = 1 }
		)

		fadeOut:Play()
		labelFade:Play()
		strokeFade:Play()

		fadeOut.Completed:Connect(function()
			notifFrame:Destroy()
		end)
	end)
end

--- Opens the seed selection panel for a specific garden plot index.
function UIController.openSeedPanel(plotIndex: number)
	UIController.closePanels()
	activePlotIndex = plotIndex

	-- Update button states based on current gold
	local currentGold = playerState.Essence or 0
	if seedPanel then
		local seedList = seedPanel:FindFirstChild("SeedList")
		if seedList then
			for _, row in seedList:GetChildren() do
				if row:IsA("Frame") then
					local plantBtn = row:FindFirstChild("PlantBtn")
					if plantBtn and plantBtn:IsA("TextButton") then
						-- Extract seed cost from button text (format: "Plant (-Xg)")
						-- We check ingredient list to find the matching ingredient
						local idStr = string.gsub(row.Name, "Seed_", "")
						local def = Ingredients[idStr]
						if def then
							local canAfford = currentGold >= def.seedCost
							plantBtn.BackgroundColor3 = if canAfford then BUTTON_COLOR else Color3.fromRGB(80, 80, 80)
							plantBtn.TextColor3 = if canAfford then TEXT_COLOR else Color3.fromRGB(120, 120, 120)
						end
					end
				end
			end
		end

		seedPanel.Visible = true
	end
end

--- Opens the brewing panel and populates it with the player's ingredients.
function UIController.openBrewPanel()
	UIController.closePanels()
	populateBrewIngredients()

	-- Reset brew button state
	if brewButton then
		brewButton.BackgroundColor3 = BUTTON_COLOR
	end
	if brewPreviewLabel then
		brewPreviewLabel.Text = Strings.SELECT_TO_BREW
		brewPreviewLabel.TextColor3 = Color3.fromRGB(150, 150, 170)
	end

	if brewPanel then
		brewPanel.Visible = true
	end
end

--- Opens the sell panel and populates it with the player's potions.
function UIController.openSellPanel()
	UIController.closePanels()
	populateSellList()

	if sellPanel then
		sellPanel.Visible = true
	end
end

--- Opens the upgrade panel (triggered from the shop/upgrade station).
function UIController.openUpgradePanel()
	UIController.closePanels()
	updateUpgradeButtons()

	if upgradePanel then
		upgradePanel.Visible = true
	end
end

--- Opens the journal panel on the specified tab (defaults to "basics").
function UIController.openJournalPanel(tabName: string?)
	UIController.closePanels()
	switchJournalTab(tabName or activeJournalTab or "basics")
	if journalPanel then
		journalPanel.Visible = true
	end
end

--- Called when a recipe discovery event arrives from the server.
--- Triggers a celebratory journal flash.
function UIController.onRecipeDiscovered(recipeId: string, recipeName: string, isSessionFirst: boolean)
	-- Show a special discovery notification
	local msg = if isSessionFirst
		then "WORLD FIRST this session: " .. recipeName .. "! Open the Journal to read the science behind it."
		else "New recipe: " .. recipeName .. "! Check your Journal to learn the science."
	UIController.showNotification(msg, Color3.fromRGB(255, 215, 50))

	-- Auto-open journal to the recipes tab after a short delay so the
	-- brew notification is visible first
	if Config.CELEBRATE_DISCOVERIES then
		task.delay(2, function()
			-- Only open if no other panel is currently open
			if journalPanel and not journalPanel.Visible then
				UIController.openJournalPanel("recipes")
			end
		end)
	end
end

--- Updates the leaderboard sidebar with a fresh top-N payload from the server.
--- @param entries Array of { rank: number, name: string, score: number }
function UIController.updateLeaderboard(entries: { { rank: number, name: string, score: number } })
	if not leaderboardRowLabels or #leaderboardRowLabels == 0 then return end

	for i = 1, TOP_N_DISPLAY do
		local label = leaderboardRowLabels[i]
		if not label then continue end

		local entry = entries[i]
		if entry then
			-- Truncate long names to keep layout clean
			local name = if #entry.name > 14 then string.sub(entry.name, 1, 13) .. "…" else entry.name
			label.Text = entry.rank .. ". " .. name .. "  " .. tostring(entry.score) .. " E"
			-- Essence colour for #1, silver for #2, bronze for #3, default otherwise
			if entry.rank == 1 then
				label.TextColor3 = GOLD_TEXT_COLOR
			elseif entry.rank == 2 then
				label.TextColor3 = Color3.fromRGB(192, 192, 192)
			elseif entry.rank == 3 then
				label.TextColor3 = Color3.fromRGB(205, 127, 50)
			else
				label.TextColor3 = TEXT_COLOR
			end
		else
			label.Text = i .. ". —"
			label.TextColor3 = Color3.fromRGB(100, 100, 120)
		end
	end
end

--- Injects the LightingController and ParticleController so the settings panel
--- Performance Mode toggle can call disableEffects() / enableAll() on them.
--- Called from Main.client.luau after all controllers are initialised.
function UIController.setPerformanceControllers(lc: any, pc: any)
	lightingController = lc
	particleController = pc
end

--- Opens the cosmetic shop panel and populates the active tab.
function UIController.openCosmeticPanel()
	UIController.closePanels()
	if cosmeticPanel then
		cosmeticPanel.Visible = true
		populateCosmeticList(activeCosmeticTab)
	end
end

--- Opens the settings panel (volume / accessibility controls).
function UIController.openSettingsPanel()
	UIController.closePanels()
	if settingsPanel then
		settingsPanel.Visible = true
	end
end

--- Closes all overlay panels.
function UIController.closePanels()
	activePlotIndex = nil
	table.clear(selectedIngredients)

	if seedPanel then seedPanel.Visible = false end
	if brewPanel then brewPanel.Visible = false end
	if sellPanel then sellPanel.Visible = false end
	if upgradePanel then upgradePanel.Visible = false end
	if journalPanel then journalPanel.Visible = false end
	if settingsPanel then settingsPanel.Visible = false end
	if cosmeticPanel then cosmeticPanel.Visible = false end
end

---------------------------------------------------------------------------
-- Rewarded Ad cooldown display
---------------------------------------------------------------------------

--- Called when the server sends an ad cooldown update.
--- Starts or stops a local tick loop to count down the button label.
function UIController.updateAdCooldown(secondsRemaining: number)
	adCooldownRemaining = secondsRemaining

	if not adButton then return end
	if not adsAllowed then return end

	-- Cancel any existing countdown loop
	if adCooldownConnection then
		adCooldownConnection:Disconnect()
		adCooldownConnection = nil
	end

	if secondsRemaining <= 0 then
		-- Ready to watch
		adButton.Text = Strings.AD_WATCH_BUTTON
		adButton.BackgroundColor3 = Color3.fromRGB(40, 130, 60)
		if adCooldownLabel then
			adCooldownLabel.Visible = false
		end
		adCooldownRemaining = 0
		return
	end

	-- Start cooldown display
	local endTime = os.clock() + secondsRemaining

	local function updateCooldownDisplay()
		local remaining = math.ceil(endTime - os.clock())
		if remaining <= 0 then
			adCooldownRemaining = 0
			adButton.Text = Strings.AD_WATCH_BUTTON
			adButton.BackgroundColor3 = Color3.fromRGB(40, 130, 60)
			if adCooldownLabel then
				adCooldownLabel.Visible = false
			end
			if adCooldownConnection then
				adCooldownConnection:Disconnect()
				adCooldownConnection = nil
			end
			return
		end
		adCooldownRemaining = remaining
		local minutes = math.floor(remaining / 60)
		local seconds = remaining % 60
		local timeStr = string.gsub(
			string.gsub(Strings.AD_COOLDOWN_SHORT, "{minutes}", tostring(minutes)),
			"{seconds}", string.format("%02d", seconds)
		)
		adButton.Text = Strings.AD_WATCH_BUTTON
		adButton.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
		if adCooldownLabel then
			adCooldownLabel.Text = timeStr
			adCooldownLabel.Visible = true
		end
	end

	-- Immediate update
	updateCooldownDisplay()

	-- Tick every second via Heartbeat
	local RunService = game:GetService("RunService")
	local lastTick = os.clock()
	adCooldownConnection = RunService.Heartbeat:Connect(function()
		if os.clock() - lastTick >= 1 then
			lastTick = os.clock()
			updateCooldownDisplay()
		end
	end)
end

---------------------------------------------------------------------------
-- Seasonal event update — called when the server broadcasts a seasonal
-- event start/change/end. Updates the seed shop to show seasonal seeds.
---------------------------------------------------------------------------
function UIController.onSeasonalUpdate(eventId: string?, eventName: string?, bannerText: string?)
	if eventId and eventName then
		UIController.showNotification(
			bannerText or ("Seasonal Event: " .. eventName .. " is now active!"),
			Color3.fromRGB(100, 200, 255)
		)
	else
		UIController.showNotification(
			"The seasonal event has ended. See you next time!",
			Color3.fromRGB(200, 200, 200)
		)
	end
	-- Re-sync state to refresh shop panel with seasonal ingredients
	-- (The server will send a StateSync shortly after SeasonalUpdate)
end

return UIController
