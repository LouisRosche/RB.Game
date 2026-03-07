--[[
	SeasonalContent.luau
	Defines all time-limited seasonal events for Alchemy Academy.

	Seasonal events run for a fixed calendar window each year. During the
	event, exclusive ingredients appear in the shop and exclusive recipes
	become brewable. Event rewards (ingredients, discoveries) persist after
	the event ends — players keep what they earned.

	Anti-dark-pattern compliance:
	  - No FOMO timers on individual items; the event window is announced
	    well in advance (2 weeks minimum) via Discord and TikTok
	  - No paid event pass required; all seasonal content is free to earn
	  - Seasonal items have no stat advantage over base ingredients
	  - Odds for seasonal mutations shown transparently in the Journal

	SETUP — before an event launches:
	  1. Set the event's `startMonth`, `startDay`, `endMonth`, `endDay`
	     to the calendar window you want.
	  2. Upload any seasonal audio and replace sound IDs in SoundController.
	  3. Deploy a game update with the new event active (update DATA_TEMPLATE
	     version if new persistent keys are added to event data).
	  4. Announce at least 14 days before start.

	TIME: uses os.time() UTC. For Studio testing set FORCE_ACTIVE below.
]]

local SeasonalContent = {}

---------------------------------------------------------------------------
-- Debug override — set to an event id string to force that event active
-- in Studio regardless of real date. Set to nil for production.
---------------------------------------------------------------------------
SeasonalContent.FORCE_ACTIVE = nil  -- e.g. "winter_festival"

---------------------------------------------------------------------------
-- Types
---------------------------------------------------------------------------

export type SeasonalIngredient = {
	id:          string,
	displayName: string,
	scienceFact: string,
	seedCost:    number,
	growthTime:  number,
	baseValue:   number,
	color:       Color3,
}

export type SeasonalRecipe = {
	id:           string,
	displayName:  string,
	ingredients:  { string },  -- exactly 2 ingredient ids (seasonal + any)
	baseValue:    number,
	description:  string,
	scienceFact:  string,
}

export type SeasonalEvent = {
	id:           string,
	name:         string,
	description:  string,
	startMonth:   number,   -- 1-12
	startDay:     number,   -- 1-31
	endMonth:     number,
	endDay:       number,
	ingredients:  { SeasonalIngredient },
	recipes:      { SeasonalRecipe },
	shopBannerText: string,  -- shown in seed shop during event
}

---------------------------------------------------------------------------
-- Event definitions
---------------------------------------------------------------------------

SeasonalContent.EVENTS: { SeasonalEvent } = {

	---------------------------------------------------------------------------
	-- Winter Festival (25 Dec – 8 Jan)
	-- Theme: cold, crystalline, light in darkness
	---------------------------------------------------------------------------
	{
		id          = "winter_festival",
		name        = "Winter Festival of Light",
		description = "The Academy celebrates the longest night with luminous experiments.",
		startMonth  = 12,
		startDay    = 25,
		endMonth    = 1,
		endDay      = 8,
		shopBannerText = "Winter Festival is here! Exclusive ingredients available for 15 days.",

		ingredients = {
			{
				id          = "frost_blossom",
				displayName = "Frost Blossom",
				scienceFact = "Snowflake geometry — every snowflake has hexagonal symmetry because water molecules bond at 104.5° angles, forcing six-fold patterns.",
				seedCost    = 80,
				growthTime  = 45,
				baseValue   = 35,
				color       = Color3.fromRGB(200, 230, 255),
			},
			{
				id          = "aurora_moss",
				displayName = "Aurora Moss",
				scienceFact = "Aurora borealis — solar wind particles collide with atmospheric gases at 100–200 km altitude, exciting atoms that release coloured light as they relax.",
				seedCost    = 120,
				growthTime  = 75,
				baseValue   = 55,
				color       = Color3.fromRGB(100, 255, 180),
			},
		},

		recipes = {
			{
				id           = "winter_solstice_brew",
				displayName  = "Solstice Brew",
				ingredients  = { "frost_blossom", "moonpetal" },
				baseValue    = 160,
				description  = "A luminescent potion brewed only during the longest night.",
				scienceFact  = "Snowflake geometry + bioluminescence — how living organisms create cold light from ordered molecular structures.",
			},
			{
				id           = "aurora_elixir",
				displayName  = "Aurora Elixir",
				ingredients  = { "aurora_moss", "starbloom" },
				baseValue    = 200,
				description  = "A shimmering elixir that colours the air around the flask.",
				scienceFact  = "Aurora borealis + nuclear fusion — the solar wind that drives auroras originates from the same nuclear reactions powering the Sun.",
			},
			{
				id           = "frozen_light",
				displayName  = "Potion of Frozen Light",
				ingredients  = { "frost_blossom", "aurora_moss" },
				baseValue    = 240,
				description  = "A crystalline potion that captures light inside its lattice.",
				scienceFact  = "Snowflake geometry + aurora borealis — both phenomena emerge from the same quantum mechanical rules governing electron energy levels.",
			},
		},
	},

	---------------------------------------------------------------------------
	-- Spring Bloom (21 Mar – 5 Apr)
	-- Theme: growth, pollination, new beginnings
	---------------------------------------------------------------------------
	{
		id          = "spring_bloom",
		name        = "Spring Bloom Festival",
		description = "The Academy's gardens erupt with rare seasonal specimens.",
		startMonth  = 3,
		startDay    = 21,
		endMonth    = 4,
		endDay      = 5,
		shopBannerText = "Spring Bloom is here! Rare garden specimens in stock for 16 days.",

		ingredients = {
			{
				id          = "pollinator_petal",
				displayName = "Pollinator Petal",
				scienceFact = "Mutualism — bees and flowers co-evolved over 100 million years. Flowers signal with UV patterns invisible to humans but visible to bees.",
				seedCost    = 90,
				growthTime  = 40,
				baseValue   = 40,
				color       = Color3.fromRGB(255, 200, 100),
			},
			{
				id          = "mycelium_bloom",
				displayName = "Mycelium Bloom",
				scienceFact = "Mycorrhizal networks — underground fungal networks connect trees, allowing them to share nutrients and chemical distress signals (the 'Wood Wide Web').",
				seedCost    = 110,
				growthTime  = 60,
				baseValue   = 50,
				color       = Color3.fromRGB(220, 180, 255),
			},
		},

		recipes = {
			{
				id           = "bloom_tonic",
				displayName  = "Bloom Tonic",
				ingredients  = { "pollinator_petal", "starbloom" },
				baseValue    = 175,
				description  = "Accelerates growth in any living thing it touches.",
				scienceFact  = "Mutualism + nuclear fusion — photosynthesis is the chain that connects solar energy to all growth on Earth.",
			},
			{
				id           = "forest_net",
				displayName  = "Potion of Forest Networks",
				ingredients  = { "mycelium_bloom", "shadowmoss" },
				baseValue    = 185,
				description  = "A dark, earthy potion that heightens awareness of connections.",
				scienceFact  = "Mycorrhizal networks + light absorption — why fungi thrive without sunlight, feeding on forest floor decay instead.",
			},
			{
				id           = "spring_grand",
				displayName  = "Grand Spring Elixir",
				ingredients  = { "pollinator_petal", "mycelium_bloom" },
				baseValue    = 260,
				description  = "The Academy's signature spring brew — tastes of fresh earth and sunlight.",
				scienceFact  = "Mutualism + mycorrhizal networks — the entire above-ground and below-ground ecosystem is one interconnected organism.",
			},
		},
	},
}

---------------------------------------------------------------------------
-- Lookup table by id
---------------------------------------------------------------------------

SeasonalContent.BY_ID: { [string]: SeasonalEvent } = {}
for _, event in SeasonalContent.EVENTS do
	SeasonalContent.BY_ID[event.id] = event
end

---------------------------------------------------------------------------
-- Ingredient lookup (across all events, by id)
---------------------------------------------------------------------------

SeasonalContent.INGREDIENT_BY_ID: { [string]: SeasonalIngredient } = {}
for _, event in SeasonalContent.EVENTS do
	for _, ing in event.ingredients do
		SeasonalContent.INGREDIENT_BY_ID[ing.id] = ing
	end
end

---------------------------------------------------------------------------
-- Recipe lookup (across all events, by id)
---------------------------------------------------------------------------

SeasonalContent.RECIPE_BY_ID: { [string]: SeasonalRecipe } = {}
for _, event in SeasonalContent.EVENTS do
	for _, recipe in event.recipes do
		SeasonalContent.RECIPE_BY_ID[recipe.id] = recipe
	end
end

return SeasonalContent
