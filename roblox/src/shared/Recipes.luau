--[[
	Recipes.luau
	Maps ingredient pair combinations to potion definitions.
	Keys are normalized: both ingredient IDs sorted alphabetically and joined with "+".
	This guarantees that lookup order never matters (Moonpetal+Fireroot == Fireroot+Moonpetal).
]]

local Config = require(script.Parent.Config)

local Recipes = {}

--============================================================================--
-- Type definitions
--============================================================================--

export type RecipeDef = {
	id: string,          -- stable potion ID for data persistence
	displayName: string, -- player-facing name
	baseValue: number,   -- essence value before rarity / cauldron bonuses
	color: Color3,       -- representative colour for UI / particles
	scienceHook: string, -- one-line real science teaser shown after discovery
}

--============================================================================--
-- Recipe table (keys are "IngredientA+IngredientB", alphabetically sorted)
--============================================================================--

Recipes.Map: { [string]: RecipeDef } = {
	-- Same-ingredient brews
	["Moonpetal+Moonpetal"] = {
		id = "LunarElixir",
		displayName = "Lunar Elixir",
		baseValue = 25,
		color = Color3.fromRGB(130, 170, 255),
		scienceHook = "Two mirrors facing each other create infinite reflections — this is a resonance cavity, the principle behind lasers!",
	},
	["Fireroot+Fireroot"] = {
		id = "BlazingTonic",
		displayName = "Blazing Tonic",
		baseValue = 35,
		color = Color3.fromRGB(255, 120, 30),
		scienceHook = "Double the heat triggers thermal runaway — energy feeds more energy, like a fire growing bigger as it burns!",
	},
	["Shadowmoss+Shadowmoss"] = {
		id = "VoidEssence",
		displayName = "Void Essence",
		baseValue = 50,
		color = Color3.fromRGB(100, 20, 160),
		scienceHook = "Combined absorption reaches near 100% — like Vantablack, the darkest material ever made by humans!",
	},
	["Starbloom+Starbloom"] = {
		id = "CelestialBrew",
		displayName = "Celestial Brew",
		baseValue = 75,
		color = Color3.fromRGB(255, 240, 100),
		scienceHook = "Double stellar energy splits into every colour at once — the same physics as a prism splitting sunlight into a rainbow!",
	},

	-- Cross-ingredient brews (keys already alphabetical)
	["Fireroot+Moonpetal"] = {
		id = "TwilightPotion",
		displayName = "Twilight Potion",
		baseValue = 30,
		color = Color3.fromRGB(180, 100, 200),
		scienceHook = "Cold moonlight + hot geothermal heat = convection currents — the same force that creates weather and ocean currents!",
	},
	["Moonpetal+Shadowmoss"] = {
		id = "PhantomDraught",
		displayName = "Phantom Draught",
		baseValue = 40,
		color = Color3.fromRGB(120, 80, 220),
		scienceHook = "Light stored + light absorbed = energy shifts to infrared — thermal cameras would see this glowing in total darkness!",
	},
	["Moonpetal+Starbloom"] = {
		id = "AstralSerum",
		displayName = "Astral Serum",
		baseValue = 50,
		color = Color3.fromRGB(180, 200, 255),
		scienceHook = "Phase-coherent light waves line up perfectly — this is exactly how lasers work, used in surgery and 3D scanning!",
	},
	["Fireroot+Shadowmoss"] = {
		id = "InfernalMix",
		displayName = "Infernal Mix",
		baseValue = 45,
		color = Color3.fromRGB(200, 50, 100),
		scienceHook = "Heat + chemical energy = exothermic reaction — the same process as burning wood, digesting food, or hand warmers!",
	},
	["Fireroot+Starbloom"] = {
		id = "SolarNectar",
		displayName = "Solar Nectar",
		baseValue = 55,
		color = Color3.fromRGB(255, 180, 50),
		scienceHook = "Earth heat + solar energy = our climate in miniature! Solar panels and wind turbines are both ultimately powered by the Sun.",
	},
	["Shadowmoss+Starbloom"] = {
		id = "EclipseTincture",
		displayName = "Eclipse Tincture",
		baseValue = 65,
		color = Color3.fromRGB(180, 130, 255),
		scienceHook = "A molecular eclipse: one ingredient blocks the other, yet both remain present — scientists study real eclipses to see the Sun's corona!",
	},
}

--============================================================================--
-- Helpers
--============================================================================--

--- Normalises two ingredient IDs into the canonical key format and returns
--- the matching recipe, or nil if the combination doesn't exist.
function Recipes.lookup(ingredientId1: string, ingredientId2: string): RecipeDef?
	-- Sort alphabetically so order never matters
	local a, b = ingredientId1, ingredientId2
	if a > b then
		a, b = b, a
	end
	local key = a .. "+" .. b
	return Recipes.Map[key]
end

--- Calculates the final Essence value of a brewed potion, applying both
--- ingredient rarity multipliers and the cauldron's value bonus.
---
--- @param recipe         The recipe definition from Recipes.Map
--- @param rarityIndex1   Index into Config.MUTATION_TIERS for the first ingredient
--- @param rarityIndex2   Index into Config.MUTATION_TIERS for the second ingredient
--- @param cauldronLevel  Current cauldron upgrade level (1-based)
--- @return               Final Essence value (floored to an integer)
function Recipes.calculateValue(
	recipe: RecipeDef,
	rarityIndex1: number,
	rarityIndex2: number,
	cauldronLevel: number
): number
	local tier1 = Config.MUTATION_TIERS[rarityIndex1]
	local tier2 = Config.MUTATION_TIERS[rarityIndex2]
	local cauldron = Config.CAULDRON_LEVELS[cauldronLevel]

	local rarity1Mult = if tier1 then tier1.multiplier else 1
	local rarity2Mult = if tier2 then tier2.multiplier else 1
	local cauldronBonus = if cauldron then cauldron.valueBonus else 1.0

	return math.floor(recipe.baseValue * rarity1Mult * rarity2Mult * cauldronBonus)
end

return Recipes
