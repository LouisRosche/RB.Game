## Recipes.gd
## Autoload singleton — recipe database and brewing logic.
##
## A recipe combines exactly two ingredients (order-independent).
## Rarity multipliers from the Roblox game are preserved so cross-game
## players recognise the value curve.
##
## Each recipe definition:
##   id            — unique key
##   display_name  — potion name shown in UI
##   ingredients   — Array[String] of exactly 2 ingredient ids (order-independent)
##   base_value    — gold value before rarity multiplier
##   description   — what the potion does in lore
##   science_note  — the combined science explained by the potion
##   chapter       — minimum chapter in which the recipe is discoverable

extends Node

# ---------------------------------------------------------------------------
# Rarity multipliers (same as Roblox Config.MUTATION_TIERS for cross-universe
# consistency; standalone uses Ingredient quality tier instead of random roll)
# ---------------------------------------------------------------------------
const RARITY_MULTIPLIER: Dictionary = {
	"Common":    1,
	"Uncommon":  2,
	"Rare":      5,
	"Epic":      15,
	"Legendary": 50,
}

# ---------------------------------------------------------------------------
# Database
# ---------------------------------------------------------------------------

## All recipes indexed by id.
var db: Dictionary = {}

## Lookup map: Set(ingredient_id_a, ingredient_id_b) → recipe_id
## Key: "{min_id}+{max_id}" (alphabetically sorted, always deterministic)
var _lookup: Dictionary = {}

func _ready() -> void:
	_register_all()

func _register(recipe: Dictionary) -> void:
	db[recipe["id"]] = recipe

	var ids: Array = recipe["ingredients"].duplicate()
	ids.sort()
	var key := ids[0] + "+" + ids[1]
	_lookup[key] = recipe["id"]

func _register_all() -> void:
	# ---- Original 10 recipes (mirrors Roblox game for cross-recognition) ----
	_register({
		"id":           "glow_potion",
		"display_name": "Potion of Glow",
		"ingredients":  ["moonpetal", "starbloom"],
		"base_value":   50,
		"description":  "A soft radiant potion that illuminates dark places.",
		"science_note": "Bioluminescence + nuclear fusion — organic light production meets stellar energy.",
		"chapter":      1,
	})
	_register({
		"id":           "heat_potion",
		"display_name": "Potion of Heat",
		"ingredients":  ["fireroot", "starbloom"],
		"base_value":   55,
		"description":  "A warming elixir used by mountain climbers.",
		"science_note": "Geothermal energy + nuclear fusion — Earth's interior heat and solar radiation share the same nuclear origin.",
		"chapter":      1,
	})
	_register({
		"id":           "void_potion",
		"display_name": "Potion of Shadows",
		"ingredients":  ["shadowmoss", "moonpetal"],
		"base_value":   60,
		"description":  "A darkening draught that suppresses all ambient light.",
		"science_note": "Light absorption + bioluminescence — what happens when you combine the darkest material with the most efficient light source?",
		"chapter":      1,
	})
	_register({
		"id":           "ignition_potion",
		"display_name": "Potion of Ignition",
		"ingredients":  ["fireroot", "shadowmoss"],
		"base_value":   65,
		"description":  "A combustion catalyst used in foundries.",
		"science_note": "Geothermal energy + light absorption — how the Earth stores and releases heat energy.",
		"chapter":      1,
	})
	_register({
		"id":           "crystal_potion",
		"display_name": "Crystal Clarity",
		"ingredients":  ["moonpetal", "crystalvine"],
		"base_value":   70,
		"description":  "A transparent elixir that sharpens vision and thought.",
		"science_note": "Bioluminescence + crystal lattices — how ordered atomic structure produces optical clarity.",
		"chapter":      1,
	})
	_register({
		"id":           "lattice_brew",
		"display_name": "Lattice Brew",
		"ingredients":  ["crystalvine", "starbloom"],
		"base_value":   75,
		"description":  "A structured elixir used in precision crafting.",
		"science_note": "Crystal lattices + nuclear fusion — how the Sun's energy crystallises in mineral formation over geological time.",
		"chapter":      1,
	})
	_register({
		"id":           "thunder_elixir",
		"display_name": "Thunder Elixir",
		"ingredients":  ["stormcap", "crystalvine"],
		"base_value":   90,
		"description":  "Charges the drinker with kinetic potential.",
		"science_note": "Triboelectric effect + crystal lattices — piezoelectric crystals generate electricity under pressure (used in spark igniters).",
		"chapter":      2,
	})
	_register({
		"id":           "abyssal_tonic",
		"display_name": "Abyssal Tonic",
		"ingredients":  ["abyssal_kelp", "shadowmoss"],
		"base_value":   95,
		"description":  "A cold, pressurised concentrate from the deep ocean.",
		"science_note": "Piezophiles + light absorption — deep-sea organisms live in permanent darkness under pressure so extreme it would crush submarines.",
		"chapter":      2,
	})
	_register({
		"id":           "storm_surge",
		"display_name": "Storm Surge",
		"ingredients":  ["stormcap", "fireroot"],
		"base_value":   100,
		"description":  "An explosive energetic brew used in mining.",
		"science_note": "Triboelectric effect + geothermal energy — volcanic lightning is real (seen during the 2010 Eyjafjallajokull eruption).",
		"chapter":      2,
	})
	_register({
		"id":           "spectrum_draught",
		"display_name": "Spectrum Draught",
		"ingredients":  ["prism_petal", "moonpetal"],
		"base_value":   130,
		"description":  "A prismatic potion that reveals hidden colours in any object.",
		"science_note": "Dispersion + bioluminescence — how some deep-sea creatures use structural colour (like butterfly wings) rather than pigment.",
		"chapter":      3,
	})

	# ---- New recipes exclusive to Origins ----
	_register({
		"id":           "solar_prism",
		"display_name": "Solar Prism",
		"ingredients":  ["prism_petal", "starbloom"],
		"base_value":   150,
		"description":  "A lens-like potion that focuses light into a cutting beam.",
		"science_note": "Dispersion + nuclear fusion — concentrating solar energy is the basis of CSP (concentrated solar power) plants.",
		"chapter":      3,
	})
	_register({
		"id":           "phyto_tonic",
		"display_name": "Phyto Tonic",
		"ingredients":  ["iron_bloom", "crystalvine"],
		"base_value":   140,
		"description":  "A soil-cleansing remedy used by Academy gardeners.",
		"science_note": "Hyperaccumulators + crystal lattices — phytoremediation can clean heavy metals from soil without excavation.",
		"chapter":      3,
	})
	_register({
		"id":           "gravity_well",
		"display_name": "Gravity Well",
		"ingredients":  ["void_spore", "abyssal_kelp"],
		"base_value":   200,
		"description":  "A dense potion that bends light around the flask.",
		"science_note": "Gravitational lensing + piezophiles — extreme pressure environments (deep ocean, neutron star surface) share surprising physics.",
		"chapter":      4,
	})
	_register({
		"id":           "void_crystal",
		"display_name": "Void Crystal",
		"ingredients":  ["void_spore", "crystalvine"],
		"base_value":   220,
		"description":  "A perfectly dark crystalline solid. Impossible by normal chemistry.",
		"science_note": "Gravitational lensing + crystal lattices — dark matter is thought to interact gravitationally but not electromagnetically.",
		"chapter":      4,
	})
	_register({
		"id":           "grand_elixir",
		"display_name": "Grand Elixir",
		"ingredients":  ["void_spore", "starbloom"],
		"base_value":   300,
		"description":  "The Academy's legendary potion. Chapters of history were written about it.",
		"science_note": "Gravitational lensing + nuclear fusion — the Grand Unification of forces is the holy grail of physics: one equation that explains everything.",
		"chapter":      4,
	})

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Returns the recipe definition for combining two ingredients, or null dict.
## Order-independent.
func lookup(id_a: String, id_b: String) -> Dictionary:
	var ids := [id_a, id_b]
	ids.sort()
	var key := ids[0] + "+" + ids[1]
	var recipe_id: String = _lookup.get(key, "")
	if recipe_id.is_empty():
		return {}
	return db.get(recipe_id, {})

## Calculate the gold value of a brewed potion.
## @param recipe       The recipe dict from lookup()
## @param rarity_a     Rarity string of the first ingredient
## @param rarity_b     Rarity string of the second ingredient
##
## NOTE: Uses averaged multipliers (not multiplicative like Roblox). This is
## intentional — the standalone game has 10 ingredients and 16 recipes vs
## Roblox's 4/10, so averaged scaling prevents late-game economy explosion.
## Roblox formula: base * mult1 * mult2 * cauldronBonus (quadratic scaling).
## Godot formula:  base * (mult1 + mult2) / 2           (linear scaling).
func calculate_value(recipe: Dictionary, rarity_a: String, rarity_b: String) -> int:
	var base: int = recipe.get("base_value", 10)
	var mult_a: int = RARITY_MULTIPLIER.get(rarity_a, 1)
	var mult_b: int = RARITY_MULTIPLIER.get(rarity_b, 1)
	var combined := (mult_a + mult_b) / 2.0
	return int(base * combined)

## Returns all recipe ids discoverable in the given chapter (or earlier).
func get_available_ids(chapter: int) -> Array[String]:
	var result: Array[String] = []
	for id: String in db:
		if db[id]["chapter"] <= chapter:
			result.append(id)
	return result

