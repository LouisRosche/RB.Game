--[[
	ParticleController.luau
	Sprint 3 client-side particle effects for Alchemy Academy.

	Manages three categories of particles:
	  1. Cauldron idle bubbles — persistent low-rate emitter on CauldronLiquid
	  2. Harvest bursts       — one-shot burst at the harvested plot, colour and
	                            count scaled to rarity tier
	  3. Brew complete burst  — mid-size burst at the cauldron when brewing finishes
	  4. Discovery fanfare    — large celebratory burst on first-ever recipe find

	All emitters are created programmatically (no asset uploads required).
	Temporary one-shot emitters are cleaned up via Debris after their
	particle lifetime expires, so memory stays flat.

	Performance mode: call ParticleController.disableAll() /  enableAll() to
	toggle everything off for low-end devices. The settings panel wires this.
]]

local Players = game:GetService("Players")
local Debris  = game:GetService("Debris")

local ParticleController = {}

---------------------------------------------------------------------------
-- Constants
---------------------------------------------------------------------------

local localPlayer = Players.LocalPlayer

-- How many seconds to retry waiting for the lab model before giving up.
local LAB_WAIT_MAX_SECONDS = 20

-- Colour mapped to each rarity tier (mirrors Config.MUTATION_TIERS).
local RARITY_COLOR: { [string]: Color3 } = {
	Common    = Color3.fromRGB(200, 200, 200),
	Uncommon  = Color3.fromRGB(0, 200, 0),
	Rare      = Color3.fromRGB(0, 100, 255),
	Epic      = Color3.fromRGB(160, 0, 255),
	Legendary = Color3.fromRGB(255, 215, 0),
}

-- Burst particle count per rarity — higher rarities are more spectacular.
local RARITY_BURST: { [string]: number } = {
	Common    = 8,
	Uncommon  = 18,
	Rare      = 30,
	Epic      = 50,
	Legendary = 90,
}

---------------------------------------------------------------------------
-- Internal state
---------------------------------------------------------------------------

local cauldronPart: BasePart?           = nil
local cauldronIdleEmitter: ParticleEmitter? = nil

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------

local function getLabModel(): Model?
	local labs = workspace:FindFirstChild("Labs")
	if not labs then return nil end
	return (labs :: Folder):FindFirstChild("Lab_" .. localPlayer.UserId) :: Model?
end

--- Returns a NumberSequence that fades in quickly and fades out slowly.
local function sizeSeq(peak: number): NumberSequence
	return NumberSequence.new({
		NumberSequenceKeypoint.new(0,    0),
		NumberSequenceKeypoint.new(0.15, peak),
		NumberSequenceKeypoint.new(1,    0),
	})
end

--- Returns a NumberSequence that fades in instantly and fades to transparent.
local function alphaSeq(): NumberSequence
	return NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(1, 1),
	})
end

--- Creates a one-shot burst emitter on `parent`, emits `count` particles,
--- then destroys itself after `lifetime` seconds.
local function burstEmitter(
	parent: BasePart,
	color: Color3 | ColorSequence,
	count: number,
	speed: NumberRange,
	lifetime: NumberRange,
	sizePeak: number,
	lightEmission: number,
	spreadDeg: number
): ParticleEmitter
	local emitter = Instance.new("ParticleEmitter")
	emitter.Rate          = 0                 -- burst only; no continuous emission
	emitter.Speed         = speed
	emitter.Lifetime      = lifetime
	emitter.SpreadAngle   = Vector2.new(spreadDeg, spreadDeg)
	emitter.LightEmission = lightEmission
	emitter.LightInfluence = 0.4
	emitter.Size          = sizeSeq(sizePeak)
	emitter.Transparency  = alphaSeq()

	if typeof(color) == "Color3" then
		emitter.Color = ColorSequence.new(color)
	else
		emitter.Color = color :: ColorSequence
	end

	emitter.Parent = parent
	emitter:Emit(count)

	-- Debris cleans up after max lifetime so we never accumulate emitters
	Debris:AddItem(emitter, lifetime.Max + 0.5)
	return emitter
end

---------------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------------

--- Initialise: wait for the player's lab to appear, then attach the
--- persistent cauldron idle bubble emitter to CauldronLiquid.
function ParticleController.init()
	task.spawn(function()
		local deadline = tick() + LAB_WAIT_MAX_SECONDS
		local labModel: Model? = nil

		repeat
			labModel = getLabModel()
			if not labModel then task.wait(0.5) end
		until labModel or tick() > deadline

		if not labModel then
			warn("[ParticleController] Lab model not found; skipping particle setup.")
			return
		end

		local liquid = labModel:FindFirstChild("CauldronLiquid") :: BasePart?
		if not liquid then
			warn("[ParticleController] CauldronLiquid not found; skipping cauldron bubbles.")
			return
		end
		cauldronPart = liquid

		-- Persistent low-rate cauldron bubble emitter
		local emitter = Instance.new("ParticleEmitter")
		emitter.Name          = "CauldronBubbles"
		emitter.Rate          = 10
		emitter.Lifetime      = NumberRange.new(0.6, 1.2)
		emitter.Speed         = NumberRange.new(2, 4)
		emitter.SpreadAngle   = Vector2.new(25, 25)
		emitter.LightEmission = 0.6
		emitter.LightInfluence = 0.3
		emitter.Size          = sizeSeq(0.30)
		emitter.Transparency  = alphaSeq()
		emitter.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0,   Color3.fromRGB(160, 90, 255)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(100, 60, 200)),
			ColorSequenceKeypoint.new(1,   Color3.fromRGB(60,  20, 160)),
		})
		emitter.Parent = liquid

		cauldronIdleEmitter = emitter
	end)
end

--- Burst particles at the harvested plot. Call from Main.client on HarvestEffect.
--- @param plotIndex number   — which plot (1-based)
--- @param rarity string     — "Common" | "Uncommon" | "Rare" | "Epic" | "Legendary"
function ParticleController.onHarvest(plotIndex: number, rarity: string)
	local labModel = getLabModel()
	if not labModel then return end

	local plotPart = labModel:FindFirstChild("Plot_" .. plotIndex) :: BasePart?
	if not plotPart then return end

	local color = RARITY_COLOR[rarity] or RARITY_COLOR.Common
	local count = RARITY_BURST[rarity] or RARITY_BURST.Common

	burstEmitter(
		plotPart,
		color,
		count,
		NumberRange.new(4, 9),
		NumberRange.new(0.5, 1.2),
		0.40,
		0.65,
		50
	)

	-- Legendary gets a second shimmer layer of gold sparks
	if rarity == "Legendary" then
		burstEmitter(
			plotPart,
			ColorSequence.new({
				ColorSequenceKeypoint.new(0,   Color3.fromRGB(255, 240, 100)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 200, 50)),
				ColorSequenceKeypoint.new(1,   Color3.fromRGB(255, 160, 0)),
			}),
			50,
			NumberRange.new(3, 6),
			NumberRange.new(1, 2.5),
			0.25,
			1.0,
			65
		)
	end
end

--- Burst particles at the cauldron when a brew completes.
function ParticleController.onBrewComplete()
	if not cauldronPart then return end

	burstEmitter(
		cauldronPart,
		ColorSequence.new({
			ColorSequenceKeypoint.new(0,   Color3.fromRGB(200, 140, 255)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(120, 255, 200)),
			ColorSequenceKeypoint.new(1,   Color3.fromRGB(80,  180, 255)),
		}),
		35,
		NumberRange.new(5, 11),
		NumberRange.new(0.8, 1.8),
		0.50,
		0.8,
		60
	)
end

--- Large celebratory multi-layer burst when a brand-new recipe is discovered.
function ParticleController.onDiscovery()
	if not cauldronPart then return end

	-- Primary: gold and violet starburst
	burstEmitter(
		cauldronPart,
		ColorSequence.new({
			ColorSequenceKeypoint.new(0,   Color3.fromRGB(255, 215, 0)),
			ColorSequenceKeypoint.new(0.4, Color3.fromRGB(255, 140, 50)),
			ColorSequenceKeypoint.new(1,   Color3.fromRGB(200, 80, 255)),
		}),
		90,
		NumberRange.new(8, 16),
		NumberRange.new(1.5, 3.5),
		0.70,
		1.0,
		80
	)

	-- Secondary: white sparkle ring after a short delay
	task.delay(0.3, function()
		if not cauldronPart then return end
		burstEmitter(
			cauldronPart,
			Color3.fromRGB(255, 255, 255),
			40,
			NumberRange.new(3, 7),
			NumberRange.new(1, 2),
			0.20,
			1.0,
			90
		)
	end)
end

--- Disable all particles (performance mode — called from settings panel).
function ParticleController.disableAll()
	if cauldronIdleEmitter then
		cauldronIdleEmitter.Enabled = false
	end
end

--- Re-enable particles after performance mode is turned off.
function ParticleController.enableAll()
	if cauldronIdleEmitter then
		cauldronIdleEmitter.Enabled = true
	end
end

return ParticleController
