--[[
	UIController.luau
	Creates and manages ALL game UI programmatically.
	Panels: HUD, Seed Selection, Brewing, Sell, Upgrades, Notifications.

	Follows the Single-Script Architecture — this is a ModuleScript required
	by Main.client.luau.
]]

---------------------------------------------------------------------------
-- Services
---------------------------------------------------------------------------
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

---------------------------------------------------------------------------
-- Shared modules
---------------------------------------------------------------------------
local Shared      = ReplicatedStorage:WaitForChild("Shared")
local Config      = require(Shared:WaitForChild("Config"))
local Ingredients = require(Shared:WaitForChild("Ingredients"))
local Recipes     = require(Shared:WaitForChild("Recipes"))
local Strings     = require(Shared:WaitForChild("Strings"))
local Network     = require(Shared:WaitForChild("Network"))

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

-- UI element references (set during init)
local hudGoldLabel: TextLabel = nil :: any
local hudLabLabel: TextLabel = nil :: any
local hudCauldronLabel: TextLabel = nil :: any

local seedPanel: Frame = nil :: any
local brewPanel: Frame = nil :: any
local sellPanel: Frame = nil :: any
local upgradePanel: Frame = nil :: any
local notificationContainer: Frame = nil :: any

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
	hud.Size = UDim2.new(0, 220, 0, 100)
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
	hudLabLabel.Text = "Lab: Starter"
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
	hudCauldronLabel.Text = "Cauldron: Basic"
	hudCauldronLabel.ZIndex = 6
	hudCauldronLabel.Parent = hud
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
		local plantBtn = createButton("PlantBtn", Strings.PLANT .. " (-" .. def.seedCost .. "g)", UDim2.new(0, 90, 0, 36), row)
		plantBtn.Position = UDim2.new(1, -98, 0.5, -18)
		plantBtn.ZIndex = 14

		plantBtn.Activated:Connect(function()
			if activePlotIndex then
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
							brewPreviewLabel.Text = "Result: " .. recipe.displayName .. " (Base: " .. recipe.baseValue .. "g)"
							brewPreviewLabel.TextColor3 = recipe.color
						else
							brewPreviewLabel.Text = "No recipe for this combination"
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
		valueLabel.Text = tostring(potion.Value) .. "g"
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
			fireRemote(Network.SellPotion, i)
			-- Server will send a StateSync which refreshes the panel;
			-- close panel for cleaner UX and let them reopen it.
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
	sellAllButton = createButton("SellAllButton", "Sell All", UDim2.new(1, 0, 0, 38), sellPanel)
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
		if potions then
			-- Sell from the end backwards so indices stay valid on the server.
			-- Each sell triggers a StateSync; we fire all at once and let the
			-- server process them sequentially.
			for i = #potions, 1, -1 do
				fireRemote(Network.SellPotion, i)
			end
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
			upgradeLabBtn.Text = Strings.UPGRADE_LAB .. " (" .. nextLab.cost .. "g)"
			upgradeLabBtn.Visible = true
		end
		if upgradeLabInfo and nextLab then
			local currentLab = Config.LAB_LEVELS[labLevel]
			local extraPlots = nextLab.plots - (currentLab and currentLab.plots or 0)
			upgradeLabInfo.Text = "+" .. extraPlots .. " plots -> " .. nextLab.name
		end
	else
		if upgradeLabBtn then
			upgradeLabBtn.Visible = false
		end
		if upgradeLabInfo then
			upgradeLabInfo.Text = "Lab: MAX LEVEL"
		end
	end

	-- Cauldron upgrade
	if cauldronLevel < Config.MAX_CAULDRON_LEVEL then
		local nextCauldron = Config.CAULDRON_LEVELS[cauldronLevel + 1]
		if nextCauldron and upgradeCauldronBtn then
			upgradeCauldronBtn.Text = Strings.UPGRADE_CAULDRON .. " (" .. nextCauldron.cost .. "g)"
			upgradeCauldronBtn.Visible = true
		end
		if upgradeCauldronInfo and nextCauldron then
			upgradeCauldronInfo.Text = "Brew: " .. nextCauldron.brewTime .. "s, +" .. math.floor((nextCauldron.valueBonus - 1) * 100) .. "% value -> " .. nextCauldron.name
		end
	else
		if upgradeCauldronBtn then
			upgradeCauldronBtn.Visible = false
		end
		if upgradeCauldronInfo then
			upgradeCauldronInfo.Text = "Cauldron: MAX LEVEL"
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
		fireRemote(Network.UpgradeCauldron)
	end)
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
-- Public API
---------------------------------------------------------------------------

--- Creates all UI elements. Called once from Main.client.luau.
function UIController.init(initialState: { [string]: any }, remotesFolder: Folder)
	playerState = initialState or {}
	remotes = remotesFolder

	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "PotionLabUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.IgnoreGuiInset = false
	screenGui.Parent = playerGui

	createHUD()
	createSeedPanel()
	createBrewPanel()
	createSellPanel()
	createUpgradePanel()
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
		hudGoldLabel.Text = Strings.GOLD .. ": " .. tostring(playerState.Gold or 0)
	end
	if hudLabLabel then
		local labLevel = playerState.LabLevel or 1
		local labDef = Config.LAB_LEVELS[labLevel]
		hudLabLabel.Text = "Lab: " .. (labDef and labDef.name or "Lv " .. labLevel) .. " (" .. (labDef and labDef.plots or "?") .. " plots)"
	end
	if hudCauldronLabel then
		local cauldronLevel = playerState.CauldronLevel or 1
		local cauldronDef = Config.CAULDRON_LEVELS[cauldronLevel]
		hudCauldronLabel.Text = "Cauldron: " .. (cauldronDef and cauldronDef.name or "Lv " .. cauldronLevel)
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

	-- After 3 seconds, fade out and destroy
	task.delay(3, function()
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
	local currentGold = playerState.Gold or 0
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

--- Closes all overlay panels.
function UIController.closePanels()
	activePlotIndex = nil
	table.clear(selectedIngredients)

	if seedPanel then seedPanel.Visible = false end
	if brewPanel then brewPanel.Visible = false end
	if sellPanel then sellPanel.Visible = false end
	if upgradePanel then upgradePanel.Visible = false end
end

return UIController
