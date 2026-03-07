## GameState.gd
## Autoload singleton — single source of truth for all in-session player data.
##
## Persisted fields are written by SaveManager.save() and loaded by
## SaveManager.load() on startup. Transient fields (current_selection,
## brewing_in_progress) are session-only.
##
## Other autoloads (Ingredients, Recipes) read GameState but never write to it
## directly — they call methods here so state changes are centralised.

extends Node

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

## Emitted when any field of the persistent state changes.
## UI scenes connect to this to refresh without polling.
signal state_changed

## Emitted when the player discovers a recipe for the first time.
## Carries the recipe id so the Journal can highlight the new entry.
signal recipe_discovered(recipe_id: String)

## Emitted when the player earns gold (UI can play a satisfying clink).
signal gold_earned(amount: int)

# ---------------------------------------------------------------------------
# Persistent state (saved to disk)
# ---------------------------------------------------------------------------

## Current gold / Essence balance.
var gold: int = 100

## Chapter progress (1-based). Gate new ingredients and story beats.
var chapter: int = 1

## Inventory: array of { "id": String, "rarity": String }
var ingredients: Array = []

## Brewed potions awaiting sale: array of { "id": String, "name": String, "value": int }
var potions: Array = []

## Set of recipe IDs the player has personally discovered (Dictionary used as set).
## key = recipe_id (String), value = true
var discovered_recipes: Dictionary = {}

## Session stats (reset on new game, accumulated across saves)
var stats: Dictionary = {
	"total_gold_earned": 0,
	"potions_brewed":    0,
	"discoveries":       0,
	"playtime_seconds":  0.0,
}

## Settings (persisted separately from game progress in SaveManager)
var settings: Dictionary = {
	"master_volume": 1.0,
	"sfx_volume":    0.8,
	"music_volume":  0.4,
	"fullscreen":    false,
}

# ---------------------------------------------------------------------------
# Inventory caps (mirrors Roblox Config; adjust here to suit the PC format)
# ---------------------------------------------------------------------------

const MAX_INGREDIENTS := 40
const MAX_POTIONS     := 30

# ---------------------------------------------------------------------------
# Transient state (session-only, never saved)
# ---------------------------------------------------------------------------

## Currently selected ingredient indices for brewing (up to 2).
var selected_indices: Array[int] = []

## True while a brew animation is playing.
var brewing_in_progress: bool = false

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	# SaveManager will call load() on its own _ready(); GameState is always
	# registered first (see project.godot autoload order), so data is ready
	# before any scene tries to read it.
	pass

func _process(delta: float) -> void:
	stats["playtime_seconds"] += delta

# ---------------------------------------------------------------------------
# Gold helpers
# ---------------------------------------------------------------------------

func add_gold(amount: int) -> void:
	gold += amount
	stats["total_gold_earned"] += amount
	gold_earned.emit(amount)
	state_changed.emit()

func spend_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	state_changed.emit()
	return true

# ---------------------------------------------------------------------------
# Ingredient inventory
# ---------------------------------------------------------------------------

func add_ingredient(ingredient_id: String, rarity: String) -> bool:
	if ingredients.size() >= MAX_INGREDIENTS:
		return false
	ingredients.append({ "id": ingredient_id, "rarity": rarity })
	state_changed.emit()
	return true

func remove_ingredient(index: int) -> void:
	if index < 0 or index >= ingredients.size():
		return
	ingredients.remove_at(index)
	state_changed.emit()

# ---------------------------------------------------------------------------
# Potion inventory
# ---------------------------------------------------------------------------

func add_potion(recipe_id: String, potion_name: String, value: int) -> bool:
	if potions.size() >= MAX_POTIONS:
		return false
	potions.append({ "id": recipe_id, "name": potion_name, "value": value })
	stats["potions_brewed"] += 1
	state_changed.emit()
	return true

func sell_potion(index: int) -> int:
	if index < 0 or index >= potions.size():
		return 0
	var potion: Dictionary = potions[index]
	var value: int = potion.get("value", 0)
	potions.remove_at(index)
	add_gold(value)
	return value

func sell_all_potions() -> int:
	var total := 0
	for potion: Dictionary in potions:
		total += potion.get("value", 0)
	potions.clear()
	if total > 0:
		add_gold(total)
	return total

# ---------------------------------------------------------------------------
# Recipe discovery
# ---------------------------------------------------------------------------

## Records a discovery. Returns true if this is a first-time discovery.
func discover_recipe(recipe_id: String) -> bool:
	if discovered_recipes.has(recipe_id):
		return false
	discovered_recipes[recipe_id] = true
	stats["discoveries"] += 1
	recipe_discovered.emit(recipe_id)
	state_changed.emit()
	return true

func has_discovered(recipe_id: String) -> bool:
	return discovered_recipes.has(recipe_id)

func discovery_count() -> int:
	return discovered_recipes.size()

# ---------------------------------------------------------------------------
# Brewing selection (transient)
# ---------------------------------------------------------------------------

## Toggle an ingredient slot in/out of the brewing selection.
## Returns true if the ingredient was added, false if removed.
func toggle_selection(index: int) -> bool:
	var pos := selected_indices.find(index)
	if pos != -1:
		selected_indices.remove_at(pos)
		return false
	if selected_indices.size() < 2:
		selected_indices.append(index)
		return true
	return false  # already have 2 selected

func clear_selection() -> void:
	selected_indices.clear()

func can_brew() -> bool:
	return selected_indices.size() == 2 and not brewing_in_progress

# ---------------------------------------------------------------------------
# New game / chapter reset
# ---------------------------------------------------------------------------

func new_game() -> void:
	gold              = 100
	chapter           = 1
	ingredients       = []
	potions           = []
	discovered_recipes = {}
	stats = {
		"total_gold_earned": 0,
		"potions_brewed":    0,
		"discoveries":       0,
		"playtime_seconds":  0.0,
	}
	selected_indices      = []
	brewing_in_progress   = false
	state_changed.emit()

func advance_chapter() -> void:
	chapter += 1
	state_changed.emit()
