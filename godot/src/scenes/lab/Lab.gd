## Lab.gd
## Attached to: res://scenes/Lab.tscn
## The main gameplay scene — players browse their ingredient inventory,
## select two ingredients, brew at the cauldron, and discover potions.
##
## Scene node structure (create in Godot editor):
##   Lab (Node2D)
##     Background (ColorRect)
##     HUD (CanvasLayer)
##       GoldLabel (Label)             -- "Essence: 100"
##       ChapterLabel (Label)          -- "Chapter 1: The Newcomer"
##       JournalButton (Button)
##       MenuButton (Button)
##     IngredientPanel (Panel)
##       IngredientList (VBoxContainer) -- populated dynamically
##     CauldronArea (Node2D)
##       CauldronSprite (Sprite2D)     -- placeholder ColorRect for MVP
##       BrewButton (Button)
##       SelectionLabel (Label)        -- "Select 2 ingredients"
##     PotionPanel (Panel)
##       PotionList (VBoxContainer)
##       SellAllButton (Button)
##     DiscoveryOverlay (CanvasLayer)  -- shown on new recipe find
##       OverlayBackground (ColorRect)
##       DiscoveryLabel (Label)
##       ScienceLabel (Label)
##       CloseButton (Button)
##     Notification (Label)            -- slides in from top, auto-fades

class_name Lab
extends Node2D

# ---------------------------------------------------------------------------
# Node references
# ---------------------------------------------------------------------------

@export var gold_label:          Label
@export var chapter_label:       Label
@export var ingredient_list:     VBoxContainer
@export var brew_button:         Button
@export var selection_label:     Label
@export var potion_list:         VBoxContainer
@export var sell_all_button:     Button
@export var discovery_overlay:   CanvasLayer
@export var discovery_label:     Label
@export var science_label:       Label
@export var overlay_close_btn:   Button
@export var notification_label:  Label

const JOURNAL_SCENE  := "res://scenes/Journal.tscn"
const MENU_SCENE     := "res://scenes/MainMenu.tscn"

# ---------------------------------------------------------------------------
# Chapter name map
# ---------------------------------------------------------------------------
const CHAPTER_NAMES: Dictionary = {
	1: "The Newcomer",
	2: "Storms and Depths",
	3: "Light and Metal",
	4: "The Grand Unification",
}

# Rarity colours for ingredient buttons
const RARITY_COLOR: Dictionary = {
	"Common":    Color(0.8, 0.8, 0.8),
	"Uncommon":  Color(0.2, 0.8, 0.2),
	"Rare":      Color(0.2, 0.4, 1.0),
	"Epic":      Color(0.6, 0.0, 1.0),
	"Legendary": Color(1.0, 0.85, 0.0),
}

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	GameState.state_changed.connect(_refresh_ui)
	GameState.recipe_discovered.connect(_on_recipe_discovered)

	if brew_button:
		brew_button.pressed.connect(_on_brew_pressed)
	if sell_all_button:
		sell_all_button.pressed.connect(_on_sell_all_pressed)
	if overlay_close_btn:
		overlay_close_btn.pressed.connect(_on_overlay_closed)

	if discovery_overlay:
		discovery_overlay.visible = false

	_refresh_ui()

	# Auto-save on scene load (in case player returns from Settings)
	SaveManager.save_game()

# ---------------------------------------------------------------------------
# UI refresh
# ---------------------------------------------------------------------------

func _refresh_ui() -> void:
	_update_hud()
	_populate_ingredient_list()
	_populate_potion_list()
	_update_brew_button()

func _update_hud() -> void:
	if gold_label:
		gold_label.text = "Essence: %d" % GameState.gold
	if chapter_label:
		var name := CHAPTER_NAMES.get(GameState.chapter, "Chapter %d" % GameState.chapter)
		chapter_label.text = "Chapter %d: %s" % [GameState.chapter, name]

func _populate_ingredient_list() -> void:
	if not ingredient_list:
		return
	for child in ingredient_list.get_children():
		child.queue_free()

	for i: int in GameState.ingredients.size():
		var entry: Dictionary = GameState.ingredients[i]
		var ing_def: Dictionary = Ingredients.get_ingredient(entry.get("id", ""))
		if ing_def.is_empty():
			continue

		var btn := Button.new()
		var rarity: String = entry.get("rarity", "Common")
		var color: Color = RARITY_COLOR.get(rarity, Color.WHITE)
		btn.text = "[%s] %s  (%s)" % [rarity, ing_def.get("display_name", "?"), ing_def.get("id", "")]
		btn.add_theme_color_override("font_color", color)

		var idx := i  # capture for closure
		btn.pressed.connect(func() -> void: _on_ingredient_selected(idx))
		ingredient_list.add_child(btn)

func _populate_potion_list() -> void:
	if not potion_list:
		return
	for child in potion_list.get_children():
		child.queue_free()

	for i: int in GameState.potions.size():
		var potion: Dictionary = GameState.potions[i]
		var lbl := Label.new()
		lbl.text = "%s — %d E" % [potion.get("name", "?"), potion.get("value", 0)]
		potion_list.add_child(lbl)

func _update_brew_button() -> void:
	if not brew_button:
		return
	brew_button.disabled = not GameState.can_brew()

	if selection_label:
		var count := GameState.selected_indices.size()
		if count == 0:
			selection_label.text = "Select 2 ingredients to brew."
		elif count == 1:
			var idx: int = GameState.selected_indices[0]
			var entry: Dictionary = GameState.ingredients[idx] if (idx >= 0 and idx < GameState.ingredients.size()) else {}
			var ing_def: Dictionary = Ingredients.get_ingredient(entry.get("id", ""))
			selection_label.text = "1 selected: %s. Pick one more." % ing_def.get("display_name", "?")
		else:
			selection_label.text = "Ready to brew! Press Brew."

# ---------------------------------------------------------------------------
# Ingredient selection
# ---------------------------------------------------------------------------

func _on_ingredient_selected(index: int) -> void:
	GameState.toggle_selection(index)
	_populate_ingredient_list()  # re-render to show highlights
	_update_brew_button()

# ---------------------------------------------------------------------------
# Brewing
# ---------------------------------------------------------------------------

func _on_brew_pressed() -> void:
	if not GameState.can_brew():
		return

	var idx_a: int = GameState.selected_indices[0]
	var idx_b: int = GameState.selected_indices[1]

	# Guard: indices still valid (state may have changed); also reject negatives
	if idx_a < 0 or idx_b < 0 or idx_a >= GameState.ingredients.size() or idx_b >= GameState.ingredients.size():
		GameState.clear_selection()
		_refresh_ui()
		return

	var entry_a: Dictionary = GameState.ingredients[idx_a]
	var entry_b: Dictionary = GameState.ingredients[idx_b]

	var recipe: Dictionary = Recipes.lookup(entry_a.get("id", ""), entry_b.get("id", ""))
	if recipe.is_empty():
		_show_notification("Those ingredients don't combine. Try a different pair.")
		GameState.clear_selection()
		_refresh_ui()
		return

	# Remove higher index first to avoid shifting
	var high := max(idx_a, idx_b) as int
	var low  := min(idx_a, idx_b) as int
	GameState.remove_ingredient(high)
	GameState.remove_ingredient(low)

	var rarity_a: String = entry_a.get("rarity", "Common")
	var rarity_b: String = entry_b.get("rarity", "Common")
	var value: int = Recipes.calculate_value(recipe, rarity_a, rarity_b)
	var potion_name: String = recipe.get("display_name", "Unknown Potion")
	var recipe_id: String   = recipe.get("id", "")

	var added := GameState.add_potion(recipe_id, potion_name, value)
	if not added:
		_show_notification("Potion shelf full! Sell some potions first.")
		return

	# Discovery check (first time brewing this recipe); side-effect: emits signal
	GameState.discover_recipe(recipe_id)
	# Always show brew confirmation; discovery overlay shows additionally for new finds
	_show_notification("Brewed %s! Worth %d Essence." % [potion_name, value])

	GameState.clear_selection()
	_refresh_ui()
	SaveManager.save_game()

func _on_recipe_discovered(recipe_id: String) -> void:
	var recipe: Dictionary = Recipes.db.get(recipe_id, {})
	if recipe.is_empty() or not discovery_overlay:
		return

	discovery_overlay.visible = true
	if discovery_label:
		discovery_label.text = "NEW DISCOVERY!\n%s" % recipe.get("display_name", "?")
	if science_label:
		science_label.text = "Science: %s" % recipe.get("science_note", "")

# ---------------------------------------------------------------------------
# Selling
# ---------------------------------------------------------------------------

func _on_sell_all_pressed() -> void:
	var total := GameState.sell_all_potions()
	if total > 0:
		_show_notification("Sold all potions for %d Essence!" % total)
		SaveManager.save_game()
	else:
		_show_notification("No potions to sell.")

# ---------------------------------------------------------------------------
# Discovery overlay
# ---------------------------------------------------------------------------

func _on_overlay_closed() -> void:
	if discovery_overlay:
		discovery_overlay.visible = false

# ---------------------------------------------------------------------------
# Notification
# ---------------------------------------------------------------------------

func _show_notification(message: String) -> void:
	if not notification_label:
		return
	notification_label.text = message
	notification_label.visible = true
	# Auto-hide after 4 seconds
	await get_tree().create_timer(4.0).timeout
	if is_instance_valid(notification_label):
		notification_label.visible = false

# ---------------------------------------------------------------------------
# Input
# ---------------------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("open_journal"):
		get_tree().change_scene_to_file("res://scenes/Journal.tscn")
	elif event.is_action_pressed("ui_cancel") and (not discovery_overlay or not discovery_overlay.visible):
		SaveManager.save_game()
		get_tree().change_scene_to_file(MENU_SCENE)
