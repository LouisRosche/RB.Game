## Ingredients.gd
## Autoload singleton — ingredient database for Alchemy Academy: Origins.
##
## Contains all ingredients available in the standalone game, including the
## original four from the Roblox game (cross-universe continuity) plus six
## new ones exclusive to this title.
##
## Each ingredient definition:
##   id           — unique key, used in save data and recipe lookups
##   display_name — shown in UI
##   description  — flavour text + real-world science hook
##   science_fact — the educational fact the ingredient teaches
##   color        — Color for procedural placeholder art (replace with sprites)
##   chapter      — minimum chapter in which this ingredient can be found/bought
##   base_value   — gold value when sold without brewing
##   growth_hint  — brief description of how the player finds this ingredient

extends Node

# ---------------------------------------------------------------------------
# Type definition (for documentation; GDScript is duck-typed at runtime)
# ---------------------------------------------------------------------------
# {
#   id:           String
#   display_name: String
#   description:  String
#   science_fact: String
#   color:        Color
#   chapter:      int       (1 = available from start)
#   base_value:   int
#   growth_hint:  String
# }

# ---------------------------------------------------------------------------
# Database
# ---------------------------------------------------------------------------

## All ingredients indexed by id for O(1) lookup.
var db: Dictionary = {}

func _ready() -> void:
	_register_all()

func _register(ingredient: Dictionary) -> void:
	db[ingredient["id"]] = ingredient

func _register_all() -> void:
	# ---- Original four (from Roblox Alchemy Academy) ----
	_register({
		"id":           "moonpetal",
		"display_name": "Moonpetal",
		"description":  "A silvery flower that only blooms under starlight.",
		"science_fact": "Bioluminescence — how fireflies and deep-sea fish produce cold light through luciferin oxidation.",
		"color":        Color(0.8, 0.8, 1.0),
		"chapter":      1,
		"base_value":   10,
		"growth_hint":  "Found in shaded gardens at night.",
	})
	_register({
		"id":           "fireroot",
		"display_name": "Fireroot",
		"description":  "A volcanic tuber that radiates warmth even when cold.",
		"science_fact": "Geothermal energy — Iceland generates 66% of its electricity from volcanic heat.",
		"color":        Color(1.0, 0.4, 0.1),
		"chapter":      1,
		"base_value":   12,
		"growth_hint":  "Grows near warm stone formations.",
	})
	_register({
		"id":           "shadowmoss",
		"display_name": "Shadowmoss",
		"description":  "A velvety black moss that absorbs nearly all light.",
		"science_fact": "Light absorption — Vantablack absorbs 99.965% of light; structural colour vs. pigment colour.",
		"color":        Color(0.1, 0.05, 0.15),
		"chapter":      1,
		"base_value":   15,
		"growth_hint":  "Thrives in deeply shaded alcoves.",
	})
	_register({
		"id":           "starbloom",
		"display_name": "Starbloom",
		"description":  "A radiant flower that hums with contained energy.",
		"science_fact": "Nuclear fusion — the Sun fuses 600 million tons of hydrogen per second, releasing 3.8×10²⁶ watts.",
		"color":        Color(1.0, 0.95, 0.3),
		"chapter":      1,
		"base_value":   18,
		"growth_hint":  "Found at dawn near hilltops.",
	})

	# ---- New ingredients exclusive to Origins ----
	_register({
		"id":           "crystalvine",
		"display_name": "Crystalvine",
		"description":  "A translucent climbing plant with a lattice-like stem.",
		"science_fact": "Crystal lattices — how atoms arrange in repeating 3D patterns to form minerals like quartz and salt.",
		"color":        Color(0.6, 0.9, 1.0),
		"chapter":      1,
		"base_value":   14,
		"growth_hint":  "Grows on mineral-rich cave walls.",
	})
	_register({
		"id":           "stormcap",
		"display_name": "Stormcap Mushroom",
		"description":  "A mushroom that crackles with static electricity after rain.",
		"science_fact": "Triboelectric effect — lightning is caused by charge separation between ice crystals in storm clouds.",
		"color":        Color(0.9, 0.9, 0.3),
		"chapter":      2,
		"base_value":   20,
		"growth_hint":  "Appears after thunderstorms.",
	})
	_register({
		"id":           "abyssal_kelp",
		"display_name": "Abyssal Kelp",
		"description":  "Deep-sea algae that thrives under crushing pressure.",
		"science_fact": "Piezophiles — organisms adapted to extreme pressure; deep-sea life uses pressure-resistant lipid membranes.",
		"color":        Color(0.0, 0.4, 0.3),
		"chapter":      2,
		"base_value":   22,
		"growth_hint":  "Found in the Academy's deepest aquifer.",
	})
	_register({
		"id":           "prism_petal",
		"display_name": "Prism Petal",
		"description":  "A flower whose petals refract light into full spectra.",
		"science_fact": "Dispersion — Isaac Newton proved white light is a mixture of all visible wavelengths (1666). Each wavelength bends differently through glass.",
		"color":        Color(1.0, 0.5, 0.8),
		"chapter":      3,
		"base_value":   30,
		"growth_hint":  "Blooms only in direct sunlight.",
	})
	_register({
		"id":           "iron_bloom",
		"display_name": "Iron Bloom",
		"description":  "A rust-red flower that absorbs iron from the soil.",
		"science_fact": "Hyperaccumulators — some plants absorb toxic metals from soil (phytoremediation); used to clean contaminated land.",
		"color":        Color(0.7, 0.2, 0.1),
		"chapter":      3,
		"base_value":   28,
		"growth_hint":  "Found near old mining sites in the Academy grounds.",
	})
	_register({
		"id":           "void_spore",
		"display_name": "Void Spore",
		"description":  "A spore that seems to bend light around it.",
		"science_fact": "Gravitational lensing — massive objects curve spacetime, bending the path of light (confirmed in 1919 during a solar eclipse).",
		"color":        Color(0.05, 0.0, 0.1),
		"chapter":      4,
		"base_value":   45,
		"growth_hint":  "Only appears during certain astronomical events.",
	})

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Returns the ingredient definition dict for the given id, or null.
func get_ingredient(id: String) -> Dictionary:
	return db.get(id, {})

## Returns all ingredient ids available in the given chapter (or earlier).
func get_available_ids(chapter: int) -> Array[String]:
	var result: Array[String] = []
	for id: String in db:
		if db[id]["chapter"] <= chapter:
			result.append(id)
	return result

