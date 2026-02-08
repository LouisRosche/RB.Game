--[[
	PlotService.luau
	Creates and manages the 3D lab environment for each player.
	Each player gets their own platform with growing plots, a cauldron,
	a shop station, and a sell station. Uses ProximityPrompts for
	player interaction.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared      = ReplicatedStorage:WaitForChild("Shared")
local Config      = require(Shared.Config)
local Ingredients = require(Shared.Ingredients)

local DataService = require(script.Parent.DataService)

local PlotService = {}

---------------------------------------------------------------------------
-- State
---------------------------------------------------------------------------
local labsFolder: Folder = nil
local playerLabs: { [number]: Model } = {} -- userId → lab Model
local playerIndex = 0 -- increments to space out labs

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------

--- Create a simple Part with common defaults.
local function makePart(props: { [string]: any }): Part
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props do
		(part :: any)[k] = v
	end
	return part
end

--- Create a BillboardGui label above a part.
local function addBillboard(parent: BasePart, text: string, textColor: Color3?)
	local bbg = Instance.new("BillboardGui")
	bbg.Size = UDim2.new(0, 200, 0, 50)
	bbg.StudsOffset = Vector3.new(0, 3, 0)
	bbg.AlwaysOnTop = true
	bbg.Parent = parent

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = textColor or Color3.fromRGB(230, 230, 255)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = bbg

	return bbg
end

--- Create a SurfaceGui label on a part's front face.
local function addSurfaceLabel(parent: BasePart, text: string)
	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Front
	sg.Parent = parent

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(230, 230, 255)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = sg
end

--- Create a ProximityPrompt on a part.
local function addPrompt(parent: BasePart, action: string, objectText: string, holdDuration: number?): ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = action
	prompt.ObjectText = objectText
	prompt.HoldDuration = holdDuration or 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = parent
	return prompt
end

---------------------------------------------------------------------------
-- Lab creation
---------------------------------------------------------------------------

--- Build the full 3D lab for a player and parent it to the Labs folder.
function PlotService.createLab(player: Player)
	local data = DataService.getData(player)
	if not data then return end

	playerIndex += 1
	local labOrigin = Vector3.new(playerIndex * Config.LAB_OFFSET, 0, 0)

	local labModel = Instance.new("Model")
	labModel.Name = "Lab_" .. player.UserId
	labModel:SetAttribute("UserId", player.UserId)

	-- Base platform
	local base = makePart({
		Name = "Base",
		Size = Vector3.new(50, 1, 30),
		Position = labOrigin + Vector3.new(0, 0.5, 0),
		Material = Enum.Material.Slate,
		Color = Color3.fromRGB(80, 80, 90),
	})
	base.Parent = labModel

	-- Player name billboard
	addBillboard(base, player.DisplayName .. "'s Potion Lab")

	-- Create plots
	local plotCount = Config.LAB_LEVELS[data.LabLevel].plots
	PlotService._createPlotParts(labModel, labOrigin, plotCount)

	-- Cauldron (cylinder at one end)
	local cauldron = makePart({
		Name = "Cauldron",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(4, 5, 5),
		Position = labOrigin + Vector3.new(15, 3, 0),
		Orientation = Vector3.new(0, 0, 90),
		Material = Enum.Material.Metal,
		Color = Color3.fromRGB(30, 30, 35),
	})
	cauldron.Parent = labModel

	-- Cauldron glow (inner liquid)
	local liquid = makePart({
		Name = "CauldronLiquid",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(1, 4, 4),
		Position = labOrigin + Vector3.new(15, 4.5, 0),
		Orientation = Vector3.new(0, 0, 90),
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(100, 50, 200),
		CanCollide = false,
	})
	liquid.Parent = labModel

	local cauldronPrompt = addPrompt(cauldron, "Brew", "Cauldron")
	cauldronPrompt.Name = "CauldronPrompt"

	-- Shop station
	local shop = makePart({
		Name = "Shop",
		Size = Vector3.new(4, 4, 2),
		Position = labOrigin + Vector3.new(-18, 2.5, 8),
		Material = Enum.Material.WoodPlanks,
		Color = Color3.fromRGB(120, 80, 50),
	})
	shop.Parent = labModel
	addSurfaceLabel(shop, "Upgrades")

	local shopPrompt = addPrompt(shop, "Upgrades", "Shop")
	shopPrompt.Name = "ShopPrompt"

	-- Sell station
	local sell = makePart({
		Name = "SellStation",
		Size = Vector3.new(4, 3, 2),
		Position = labOrigin + Vector3.new(-18, 2, -8),
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(50, 150, 80),
	})
	sell.Parent = labModel
	addSurfaceLabel(sell, "Sell Potions")

	local sellPrompt = addPrompt(sell, "Sell", "Sell Station")
	sellPrompt.Name = "SellPrompt"

	-- Spawn the player at their lab
	labModel.Parent = labsFolder
	playerLabs[player.UserId] = labModel

	-- Move player to their lab
	task.defer(function()
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			player.Character.HumanoidRootPart.CFrame = CFrame.new(labOrigin + Vector3.new(-5, 5, 0))
		end
	end)
end

--- Internal: create plot Part instances in the lab model.
function PlotService._createPlotParts(labModel: Model, labOrigin: Vector3, plotCount: number)
	for i = 1, plotCount do
		local xOffset = (i - 1) * Config.PLOT_SPACING - ((plotCount - 1) * Config.PLOT_SPACING / 2)
		local plotPos = labOrigin + Vector3.new(xOffset, 1, -5)

		local plotPart = makePart({
			Name = "Plot_" .. i,
			Size = Config.PLOT_SIZE,
			Position = plotPos,
			Material = Enum.Material.Ground,
			Color = Color3.fromRGB(100, 65, 30),
		})
		plotPart:SetAttribute("PlotIndex", i)
		plotPart.Parent = labModel

		local prompt = addPrompt(plotPart, "Plant", "Empty Plot")
		prompt.Name = "PlotPrompt"
	end
end

---------------------------------------------------------------------------
-- Plot visual updates
---------------------------------------------------------------------------

function PlotService.updatePlotVisual(player: Player, plotIndex: number)
	local lab = playerLabs[player.UserId]
	if not lab then return end

	local data = DataService.getData(player)
	if not data then return end

	local plotPart = lab:FindFirstChild("Plot_" .. plotIndex)
	if not plotPart then return end

	local plot = data.Plots[plotIndex]
	if not plot then return end

	-- Clear existing plant visual
	local existingPlant = plotPart:FindFirstChild("Plant")
	if existingPlant then
		existingPlant:Destroy()
	end
	local existingParticles = plotPart:FindFirstChild("ReadyParticles")
	if existingParticles then
		existingParticles:Destroy()
	end

	-- Update prompt
	local prompt = plotPart:FindFirstChildWhichIsA("ProximityPrompt")

	if plot.State == "Empty" then
		plotPart.Color = Color3.fromRGB(100, 65, 30)
		if prompt then
			prompt.Enabled = true
			prompt.ActionText = "Plant"
			prompt.ObjectText = "Empty Plot"
		end

	elseif plot.State == "Growing" then
		plotPart.Color = Color3.fromRGB(80, 55, 25)
		-- Add a small seedling
		local ingredientDef = Ingredients[plot.IngredientId]
		local plant = makePart({
			Name = "Plant",
			Size = Vector3.new(1, 1, 1),
			Position = plotPart.Position + Vector3.new(0, 1, 0),
			Material = Enum.Material.Grass,
			Color = if ingredientDef then ingredientDef.color else Color3.fromRGB(0, 180, 0),
			CanCollide = false,
		})
		plant.Parent = plotPart
		if prompt then
			prompt.Enabled = false
		end

	elseif plot.State == "Ready" then
		plotPart.Color = Color3.fromRGB(60, 45, 20)
		-- Full-size plant
		local ingredientDef = Ingredients[plot.IngredientId]
		local plant = makePart({
			Name = "Plant",
			Size = Vector3.new(2, 3, 2),
			Position = plotPart.Position + Vector3.new(0, 2.5, 0),
			Material = Enum.Material.Grass,
			Color = if ingredientDef then ingredientDef.color else Color3.fromRGB(0, 200, 0),
			CanCollide = false,
		})
		plant.Parent = plotPart

		-- Sparkle particles to signal readiness
		local particles = Instance.new("ParticleEmitter")
		particles.Name = "ReadyParticles"
		particles.Rate = 5
		particles.Lifetime = NumberRange.new(1, 2)
		particles.Speed = NumberRange.new(1, 3)
		particles.SpreadAngle = Vector2.new(30, 30)
		particles.Color = ColorSequence.new(
			if ingredientDef then ingredientDef.color else Color3.fromRGB(255, 255, 100)
		)
		particles.Size = NumberSequence.new(0.3, 0)
		particles.Parent = plotPart

		local displayName = if ingredientDef then ingredientDef.displayName else plot.IngredientId
		if prompt then
			prompt.Enabled = true
			prompt.ActionText = "Harvest"
			prompt.ObjectText = displayName .. " (" .. (plot.Rarity or "Common") .. ")"
		end
	end
end

---------------------------------------------------------------------------
-- Upgrades & cleanup
---------------------------------------------------------------------------

function PlotService.upgradeLab(player: Player)
	local lab = playerLabs[player.UserId]
	if not lab then return end
	local data = DataService.getData(player)
	if not data then return end

	local base = lab:FindFirstChild("Base")
	if not base then return end
	local labOrigin = base.Position - Vector3.new(0, 0.5, 0)

	-- Count existing plots
	local existingCount = 0
	for _, child in lab:GetChildren() do
		if child.Name:match("^Plot_") then
			existingCount += 1
		end
	end

	local newTotal = Config.LAB_LEVELS[data.LabLevel].plots
	if newTotal <= existingCount then return end

	-- Add new plot parts
	for i = existingCount + 1, newTotal do
		local xOffset = (i - 1) * Config.PLOT_SPACING - ((newTotal - 1) * Config.PLOT_SPACING / 2)
		local plotPos = labOrigin + Vector3.new(xOffset, 1, -5)

		local plotPart = makePart({
			Name = "Plot_" .. i,
			Size = Config.PLOT_SIZE,
			Position = plotPos,
			Material = Enum.Material.Ground,
			Color = Color3.fromRGB(100, 65, 30),
		})
		plotPart:SetAttribute("PlotIndex", i)
		plotPart.Parent = lab

		local prompt = addPrompt(plotPart, "Plant", "Empty Plot")
		prompt.Name = "PlotPrompt"
	end
end

function PlotService.destroyLab(player: Player)
	local lab = playerLabs[player.UserId]
	if lab then
		lab:Destroy()
		playerLabs[player.UserId] = nil
	end
end

function PlotService.getPlotPart(player: Player, plotIndex: number): BasePart?
	local lab = playerLabs[player.UserId]
	if not lab then return nil end
	return lab:FindFirstChild("Plot_" .. plotIndex)
end

---------------------------------------------------------------------------
-- Init
---------------------------------------------------------------------------

function PlotService.init()
	labsFolder = Instance.new("Folder")
	labsFolder.Name = "Labs"
	labsFolder.Parent = workspace
end

return PlotService
