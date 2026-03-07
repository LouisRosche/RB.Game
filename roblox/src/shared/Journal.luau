--[[
	Journal.luau
	Educational content for the Alchemist's Journal.

	Each ingredient has a scienceNote explaining a real-world concept the
	ingredient is metaphorically based on. Each recipe has an alchemyNote
	explaining *why* those ingredients combine the way they do (conceptual
	chemistry / natural science for ages 8-16).

	The goal is that players learn something true about the world through
	play — curiosity-first, zero pressure.
]]

local Journal = {}

--============================================================================--
-- Ingredient science notes
-- Keyed by ingredient ID to match Ingredients.luau
--============================================================================--

Journal.IngredientNotes: { [string]: string } = {
	Moonpetal = [[
The Moon doesn't produce its own light — it reflects sunlight.
Moonpetal flowers use a mirror-like surface to capture and store
that reflected light during the night, releasing it slowly as a
gentle blue glow. This is called BIOLUMINESCENCE — the same trick
used by fireflies, deep-sea fish, and some jellyfish!
]],

	Fireroot = [[
Deep underground, heat from Earth's molten core warms rocks and
water. Fireroot taps into this geothermal energy through its roots,
storing thermal energy in its fibrous cells. Scientists use this
same principle in geothermal power plants to generate clean
electricity — heat from the Earth with zero fuel burned!
]],

	Shadowmoss = [[
Some plants thrive in near-total darkness, like the mosses in deep
caves. They survive through CHEMOSYNTHESIS — making energy from
chemicals instead of sunlight. Shadowmoss takes this further,
using shadow itself as an energy source, absorbing photons that
other plants reflect away. Real mosses are also key players in
ecosystems, holding moisture and enriching soil.
]],

	Starbloom = [[
Stars aren't just pretty lights — they're enormous nuclear
reactors fusing hydrogen into helium and releasing energy as
light. Starbloom seeds germinate only when struck by starlight
of exactly the right wavelength, then store that stellar energy
in golden petals. The study of starlight (spectroscopy) lets
scientists know what distant stars are made of, from Earth!
]],
}

--============================================================================--
-- Recipe alchemy notes
-- Keyed by recipe ID to match Recipes.luau
--============================================================================--

Journal.RecipeNotes: { [string]: string } = {
	LunarElixir = [[
When two Moonpetals are combined, their stored reflected light
amplifies — like holding two mirrors face-to-face. The result
is a stable loop of captured moonlight. In optics, this is
called a RESONANCE CAVITY, and it's the principle behind lasers!
Lunar Elixir glows with the same cool blue as the reflected Moon.
]],

	BlazingTonic = [[
Two Fireroots double the geothermal energy in a single vessel.
The heat triggers a THERMAL RUNAWAY reaction — energy feeds more
energy, like a fire growing bigger as it produces heat. This is
why tonic turns vivid orange-red: iron in the root oxidises
(rusts) instantly at high temperature, releasing a burst of colour.
Rust on metal is the same process, just much, much slower!
]],

	VoidEssence = [[
Shadowmoss absorbs all visible light. When you combine two
samples, the total absorption reaches near 100% — the mixture
appears almost perfectly BLACK, like Vantablack, the darkest
man-made material ever created. Real Vantablack is made from
carbon nanotubes and absorbs 99.965% of light. Scientists use
it to eliminate stray light in telescope lenses and cameras.
]],

	CelestialBrew = [[
Two Starbloom petals carry enough stellar energy to undergo a
miniature NUCLEAR-STYLE FUSION of their own energy fields. The
result is a golden brew that emits photons across many wavelengths
at once — white light refracted into every colour, like a prism!
Rainbows form by the same principle: water droplets split sunlight
into its component colours (the visible spectrum).
]],

	TwilightPotion = [[
Moonlight (cold, reflected) meets Fireroot (hot, stored heat).
Where cold and hot meet, you get CONVECTION — warm fluid rises,
cool fluid sinks, creating swirling currents. This is exactly
how weather systems form: warm air from the equator meets cold
polar air, spinning into storms and trade winds. Twilight Potion
swirls with those same hypnotic purple currents.
]],

	PhantomDraught = [[
Shadowmoss absorbs light; Moonpetal stores light. Mixed together,
they create a SELF-CANCELLING system — the absorbed light feeds
the stored light, which gets absorbed again, in an endless loop.
The energy vanishes from the visible spectrum and shifts into
INFRARED (heat we can't see). Thermal cameras would show this
potion glowing, even in total darkness!
]],

	AstralSerum = [[
Moonpetal's reflected starlight combines with Starbloom's direct
stellar energy to create a PHASE-COHERENT mixture — all the light
waves line up perfectly. This is LASER SCIENCE: coherent light
is focused, powerful, and can travel enormous distances without
spreading out. Actual lasers are used in surgery, 3D scanning,
and even measuring the exact distance to the Moon!
]],

	InfernalMix = [[
Fireroot heat + Shadowmoss chemical energy = EXOTHERMIC REACTION,
one that releases energy to its surroundings as heat and light.
Burning wood, digesting food, and hand-warmer packets are all
exothermic reactions. The crimson colour comes from excited
carbon atoms — the same glow you see in a charcoal fire or a
blacksmith's furnace. Safety first: real exothermic reactions
can be dangerous — always respect fire!
]],

	SolarNectar = [[
Fireroot (Earth heat) + Starbloom (solar energy) = the same
energy duo that powers our entire climate. The Sun warms the
oceans; the oceans warm the air; CONVECTION and wind carry that
energy around the planet. Solar Nectar captures this planetary
energy cycle in miniature. Solar panels and wind turbines are
both ultimately powered by the same source: our star, the Sun.
]],

	EclipseTincture = [[
During a solar eclipse, the Moon blocks sunlight. In this potion,
Shadowmoss (total light absorber) is combined with Starbloom
(stellar energy) creating a forced artificial eclipse at the
molecular level — one ingredient perpetually blocking the other,
yet both still present. The tension produces a shimmering lavender
glow at the boundary layers. Scientists study eclipses to learn
about the Sun's outer atmosphere (the corona), normally invisible!
]],
}

--============================================================================--
-- Rarity science notes (shown in journal)
--============================================================================--

Journal.RarityNotes: { [string]: string } = {
	Common = "Most plants grow under ordinary conditions — reliable and predictable. Science depends on reproducible results!",
	Uncommon = "Slightly unusual growing conditions (temperature, humidity, light angle) produced a more potent specimen. Small variables, bigger outcomes.",
	Rare = "A rare confluence of ideal conditions — like a perfect storm, but gentle. Nature produces these occasionally, and they're worth studying!",
	Epic = "Extraordinary growing conditions: this ingredient received near-perfect energy at every growth stage. Scientists call this 'optimal yield'.",
	Legendary = "Once-in-a-generation growth. Even with ideal conditions, the probability is 1 in 100 — a reminder that nature sometimes surprises us all.",
}

--============================================================================--
-- How to play / onboarding notes (shown in journal's 'Basics' tab)
--============================================================================--

Journal.HowToPlay: { string } = {
	"Welcome to the Alchemy Academy! Your lab is a place of DISCOVERY, not pressure.",
	"Plant seeds in your garden plots. They grow even when you're away — no need to rush!",
	"Harvest ingredients when they're ready. Each one has a rarity determined by chance (shown in the Odds tab).",
	"Combine two ingredients at the Cauldron to brew a potion. Some combinations haven't been discovered yet — experiment!",
	"Sell potions to earn Essence. Essence lets you upgrade your lab and unlock more ingredients.",
	"Open the Journal anytime to read about the real science behind your ingredients.",
	"You can visit other players' labs to see what they've discovered!",
	"There's no losing condition. Take your time, be curious, and enjoy the process.",
}

--============================================================================--
-- Fun facts (shown randomly in the journal)
--============================================================================--

Journal.FunFacts: { string } = {
	"Bioluminescence evolved independently in nature over 40 separate times!",
	"The deepest geothermal vent ever found is 5 km below the ocean surface.",
	"Some cave mosses have survived without sunlight for over 500 years.",
	"The nearest star beyond our Sun is Proxima Centauri — 4.24 light-years away.",
	"A lunar eclipse turns the Moon red because Earth's atmosphere bends red light.",
	"The word 'alchemy' comes from Arabic: al-kimiya, meaning 'the art of transformation'.",
	"Medieval alchemists tried to turn lead into gold — and accidentally invented chemistry!",
	"Vantablack is so dark that 3D shapes painted with it look completely flat.",
	"Geothermal energy powers nearly 100% of Iceland's electricity and heating.",
	"Laser stands for: Light Amplification by Stimulated Emission of Radiation.",
}

return Journal
