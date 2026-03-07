--[[
	LightingController.luau
	Sprint 3 visual polish — configures Lighting service effects to give
	Alchemy Academy a consistent atmospheric feel: warm, magical lab interior
	with subtle bloom on neon elements and gentle ambient haze.

	Design intent:
	  - Warm amber-violet colour grade (alchemy / candlelit lab feeling)
	  - Soft bloom so CauldronLiquid (Neon material) glows attractively
	  - Light atmosphere for mild depth cues without obscuring the small lab
	  - Works on low-end mobile: all effects are minimal-cost post-processing
	  - Does not override Roblox default sky (avoids asset upload requirement)

	NOTE: Roblox Lighting properties are shared across all clients connected
	to the same server place. This script runs locally on each client, but
	because these are read-only aesthetic effects (not gameplay-affecting),
	running them per-client is intentional and standard practice.
]]

local Lighting = game:GetService("Lighting")

local LightingController = {}

---------------------------------------------------------------------------
-- Lighting properties
-- Tweak these numbers in Studio → Lighting to find the feel you want,
-- then paste the final values back here.
---------------------------------------------------------------------------
local AMBIENT         = Color3.fromRGB(60, 40, 80)    -- deep purple ambient shadow
local OUTDOOR_AMBIENT = Color3.fromRGB(90, 60, 110)   -- slightly warm violet
local BRIGHTNESS      = 1.2                            -- slightly brighter than default
local CLOCK_TIME      = 14                             -- daytime sun angle (2 PM)

-- ColorCorrection: warm tint + slight desaturation for a "studio fantasy" look
local CC_BRIGHTNESS   = 0.03
local CC_CONTRAST     = 0.08
local CC_SATURATION   = -0.05
local CC_TINT_COLOR   = Color3.fromRGB(255, 240, 220)  -- warm amber cast

-- Bloom: neon CauldronLiquid glow and particle glow
local BLOOM_INTENSITY   = 0.4
local BLOOM_SIZE        = 24
local BLOOM_THRESHOLD   = 0.9 -- only blow out very bright Neon parts

-- Atmosphere: soft indoor haze
local ATMOSPHERE_DENSITY      = 0.20
local ATMOSPHERE_OFFSET       = 0.15
local ATMOSPHERE_COLOR        = Color3.fromRGB(200, 180, 230)
local ATMOSPHERE_DECAY        = Color3.fromRGB(100, 80, 130)
local ATMOSPHERE_GLARE        = 0.05
local ATMOSPHERE_HAZE         = 0.3

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------

local function getOrCreate(className: string, name: string): Instance
	local existing = Lighting:FindFirstChildOfClass(className)
	if existing then
		return existing
	end
	local inst = Instance.new(className)
	inst.Name = name
	inst.Parent = Lighting
	return inst
end

---------------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------------

function LightingController.init()
	-- Global lighting properties
	Lighting.Ambient        = AMBIENT
	Lighting.OutdoorAmbient = OUTDOOR_AMBIENT
	Lighting.Brightness     = BRIGHTNESS
	Lighting.ClockTime      = CLOCK_TIME
	Lighting.FogEnd         = 1000   -- disable default fog (Atmosphere replaces it)

	-- ColorCorrection
	local cc = getOrCreate("ColorCorrectionEffect", "AlchemyColorCorrection") :: ColorCorrectionEffect
	cc.Brightness = CC_BRIGHTNESS
	cc.Contrast   = CC_CONTRAST
	cc.Saturation = CC_SATURATION
	cc.TintColor  = CC_TINT_COLOR
	cc.Enabled    = true

	-- BloomEffect
	local bloom = getOrCreate("BloomEffect", "AlchemyBloom") :: BloomEffect
	bloom.Intensity  = BLOOM_INTENSITY
	bloom.Size       = BLOOM_SIZE
	bloom.Threshold  = BLOOM_THRESHOLD
	bloom.Enabled    = true

	-- Atmosphere
	local atmo = getOrCreate("Atmosphere", "AlchemyAtmosphere") :: Atmosphere
	atmo.Density      = ATMOSPHERE_DENSITY
	atmo.Offset       = ATMOSPHERE_OFFSET
	atmo.Color        = ATMOSPHERE_COLOR
	atmo.Decay        = ATMOSPHERE_DECAY
	atmo.Glare        = ATMOSPHERE_GLARE
	atmo.Haze         = ATMOSPHERE_HAZE
	atmo.Enabled      = true
end

--- Disable all effects (called if player opts into "performance mode" in future).
function LightingController.disableEffects()
	for _, child in Lighting:GetChildren() do
		if child:IsA("PostEffect") or child:IsA("Atmosphere") then
			child.Enabled = false
		end
	end
end

return LightingController
