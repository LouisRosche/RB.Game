--[[
	Cosmetics.luau
	Defines all purchasable cosmetic items for Alchemy Academy.

	Design philosophy (CLAUDE.md):
	  - Cosmetics are purely visual — zero gameplay advantage
	  - All items have transparent pricing; no mystery bundles or loot boxes
	  - A free starter set is always available so the shop never feels mandatory
	  - Items are grouped by category for UI presentation

	Each cosmetic definition:
	  id         — unique string key, stored in player data
	  name       — display name shown in the shop UI
	  category   — "LabTheme" | "CauldronTint" | "HarvestParticles"
	  price      — Robux price (Developer Product); 0 = free
	  productId  — Roblox Developer Product ID (placeholder until products are
	               created in Creator Hub → Monetization → Developer Products)
	  description — one-line UI subtitle
	  preview    — table of visual properties used by PlotService/ParticleController
	               to apply the cosmetic in-game

	SETUP — before launch:
	  1. Create each item as a Developer Product in Creator Hub.
	  2. Replace the placeholder productId (999xxxxxx) with the real ID.
	  3. Register the productId → cosmeticId mapping in MonetizationService.PRODUCT_MAP.
]]

local Cosmetics = {}

---------------------------------------------------------------------------
-- Type
---------------------------------------------------------------------------

export type CosmeticDef = {
	id:          string,
	name:        string,
	category:    "LabTheme" | "CauldronTint" | "HarvestParticles",
	price:       number,
	productId:   number,
	description: string,
	-- Visual data consumed by the cosmetic-application functions.
	-- LabTheme:          { wall: Color3, floor: Color3, accent: Color3 }
	-- CauldronTint:      { color: ColorSequence }
	-- HarvestParticles:  { color: ColorSequence }
	preview:     { [string]: any },
}

---------------------------------------------------------------------------
-- Item definitions
---------------------------------------------------------------------------

-- CATEGORY: LabTheme
-- Changes the wall, floor, and accent colours of the player's lab model.
-- PlotService.applyLabTheme() reads the preview table and sets Part.Color.

local LAB_THEMES: { CosmeticDef } = {
	{
		id          = "theme_midnight",
		name        = "Midnight Lab",
		category    = "LabTheme",
		price       = 0,         -- free default theme
		productId   = 0,
		description = "The classic deep-purple Alchemy Academy lab.",
		preview     = {
			wall   = Color3.fromRGB(30,  25,  50),
			floor  = Color3.fromRGB(20,  15,  35),
			accent = Color3.fromRGB(100, 80, 200),
		},
	},
	{
		id          = "theme_sunstone",
		name        = "Sunstone Lab",
		category    = "LabTheme",
		price       = 50,
		productId   = 9990001,  -- ⚠ replace with real Developer Product ID
		description = "Warm amber and gold — feels like a cosy wizard's study.",
		preview     = {
			wall   = Color3.fromRGB(80,  55,  20),
			floor  = Color3.fromRGB(55,  38,  12),
			accent = Color3.fromRGB(255, 190, 50),
		},
	},
	{
		id          = "theme_verdant",
		name        = "Verdant Lab",
		category    = "LabTheme",
		price       = 50,
		productId   = 9990002,
		description = "Forest greens and mossy stones — nature meets alchemy.",
		preview     = {
			wall   = Color3.fromRGB(25,  65,  30),
			floor  = Color3.fromRGB(15,  45,  20),
			accent = Color3.fromRGB(80,  200, 90),
		},
	},
	{
		id          = "theme_void",
		name        = "Void Lab",
		category    = "LabTheme",
		price       = 100,
		productId   = 9990003,
		description = "Pure black walls with neon outlines. For the advanced alchemist.",
		preview     = {
			wall   = Color3.fromRGB(8,   8,   12),
			floor  = Color3.fromRGB(4,   4,   8),
			accent = Color3.fromRGB(0,   240, 200),
		},
	},
	{
		id          = "theme_celestial",
		name        = "Celestial Lab",
		category    = "LabTheme",
		price       = 100,
		productId   = 9990004,
		description = "Deep-space blue and silver starlight. Brew under the stars.",
		preview     = {
			wall   = Color3.fromRGB(10,  20,  55),
			floor  = Color3.fromRGB(5,   12,  38),
			accent = Color3.fromRGB(180, 200, 255),
		},
	},
}

-- CATEGORY: CauldronTint
-- Replaces the particle colour of the cauldron idle bubble emitter and
-- brew-complete burst. ParticleController reads the active CauldronTint.

local CAULDRON_TINTS: { CosmeticDef } = {
	{
		id          = "cauldron_default",
		name        = "Mystic Purple",
		category    = "CauldronTint",
		price       = 0,
		productId   = 0,
		description = "The default violet-purple cauldron bubbles.",
		preview     = {
			color = ColorSequence.new({
				ColorSequenceKeypoint.new(0,   Color3.fromRGB(160, 90,  255)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(100, 60,  200)),
				ColorSequenceKeypoint.new(1,   Color3.fromRGB(60,  20,  160)),
			}),
		},
	},
	{
		id          = "cauldron_ember",
		name        = "Ember Cauldron",
		category    = "CauldronTint",
		price       = 50,
		productId   = 9990005,
		description = "Red and orange bubbles — volcanic alchemist energy.",
		preview     = {
			color = ColorSequence.new({
				ColorSequenceKeypoint.new(0,   Color3.fromRGB(255, 80,  20)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(220, 40,  10)),
				ColorSequenceKeypoint.new(1,   Color3.fromRGB(160, 20,  5)),
			}),
		},
	},
	{
		id          = "cauldron_frost",
		name        = "Frost Cauldron",
		category    = "CauldronTint",
		price       = 50,
		productId   = 9990006,
		description = "Icy blue and white — a cryomancer's cauldron.",
		preview     = {
			color = ColorSequence.new({
				ColorSequenceKeypoint.new(0,   Color3.fromRGB(180, 230, 255)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(100, 180, 240)),
				ColorSequenceKeypoint.new(1,   Color3.fromRGB(40,  120, 200)),
			}),
		},
	},
	{
		id          = "cauldron_bloom",
		name        = "Bloom Cauldron",
		category    = "CauldronTint",
		price       = 75,
		productId   = 9990007,
		description = "Pink and violet blossoms — a floramancer's touch.",
		preview     = {
			color = ColorSequence.new({
				ColorSequenceKeypoint.new(0,   Color3.fromRGB(255, 120, 200)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200, 80,  180)),
				ColorSequenceKeypoint.new(1,   Color3.fromRGB(140, 40,  160)),
			}),
		},
	},
}

-- CATEGORY: HarvestParticles
-- Replaces the colour scheme of harvest burst particles.
-- ParticleController.onHarvest() checks the active HarvestParticles cosmetic.

local HARVEST_PARTICLES: { CosmeticDef } = {
	{
		id          = "harvest_default",
		name        = "Classic Sparks",
		category    = "HarvestParticles",
		price       = 0,
		productId   = 0,
		description = "The default rarity-coloured harvest sparks.",
		preview     = {
			-- nil means "use rarity colour" — handled by ParticleController default path
			color = nil,
		},
	},
	{
		id          = "harvest_confetti",
		name        = "Confetti Burst",
		category    = "HarvestParticles",
		price       = 75,
		productId   = 9990008,
		description = "Rainbow confetti on every harvest — pure celebration.",
		preview     = {
			color = ColorSequence.new({
				ColorSequenceKeypoint.new(0,    Color3.fromRGB(255, 80,  80)),
				ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 200, 0)),
				ColorSequenceKeypoint.new(0.5,  Color3.fromRGB(80,  255, 80)),
				ColorSequenceKeypoint.new(0.75, Color3.fromRGB(80,  80,  255)),
				ColorSequenceKeypoint.new(1,    Color3.fromRGB(255, 80,  255)),
			}),
		},
	},
	{
		id          = "harvest_stars",
		name        = "Gold Stars",
		category    = "HarvestParticles",
		price       = 75,
		productId   = 9990009,
		description = "Golden star particles — every harvest feels Legendary.",
		preview     = {
			color = ColorSequence.new({
				ColorSequenceKeypoint.new(0,   Color3.fromRGB(255, 240, 100)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 200, 50)),
				ColorSequenceKeypoint.new(1,   Color3.fromRGB(200, 160, 0)),
			}),
		},
	},
	{
		id          = "harvest_hearts",
		name        = "Heart Burst",
		category    = "HarvestParticles",
		price       = 100,
		productId   = 9990010,
		description = "Pink hearts bloom on every harvest. Wholesome alchemy.",
		preview     = {
			color = ColorSequence.new({
				ColorSequenceKeypoint.new(0,   Color3.fromRGB(255, 150, 180)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 100, 150)),
				ColorSequenceKeypoint.new(1,   Color3.fromRGB(220, 60,  120)),
			}),
		},
	},
}

---------------------------------------------------------------------------
-- Merged lookup tables
---------------------------------------------------------------------------

--- All cosmetics in a flat array (used for shop panel generation).
Cosmetics.ALL: { CosmeticDef } = {}

--- Lookup by id string for O(1) access.
Cosmetics.BY_ID: { [string]: CosmeticDef } = {}

--- Lookup by Developer Product ID (0-keyed entries are skipped — free items).
Cosmetics.BY_PRODUCT_ID: { [number]: CosmeticDef } = {}

local function registerList(list: { CosmeticDef })
	for _, def in list do
		table.insert(Cosmetics.ALL, def)
		Cosmetics.BY_ID[def.id]  = def
		if def.productId ~= 0 then
			Cosmetics.BY_PRODUCT_ID[def.productId] = def
		end
	end
end

registerList(LAB_THEMES)
registerList(CAULDRON_TINTS)
registerList(HARVEST_PARTICLES)

--- Returns all items in a given category, sorted by price ascending.
function Cosmetics.getCategory(category: string): { CosmeticDef }
	local result: { CosmeticDef } = {}
	for _, def in Cosmetics.ALL do
		if def.category == category then
			table.insert(result, def)
		end
	end
	table.sort(result, function(a, b) return a.price < b.price end)
	return result
end

--- Default active cosmetics for new players (free items).
Cosmetics.DEFAULTS = {
	LabTheme          = "theme_midnight",
	CauldronTint      = "cauldron_default",
	HarvestParticles  = "harvest_default",
}

return Cosmetics
