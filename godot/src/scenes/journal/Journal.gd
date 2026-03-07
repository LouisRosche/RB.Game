## Journal.gd
## Attached to: res://scenes/Journal.tscn
## Displays the Alchemist's Journal — all discovered recipes with their
## science explanations, plus a full ingredient index.
##
## Scene node structure (create in Godot editor):
##   Journal (Node2D)
##     Background (ColorRect)
##     Header (Label)               -- "Alchemist's Journal"
##     TabContainer (TabContainer)
##       RecipesTab (ScrollContainer)
##         RecipeList (VBoxContainer)
##       IngredientsTab (ScrollContainer)
##         IngredientList (VBoxContainer)
##     ProgressLabel (Label)        -- "X / Y recipes discovered"
##     CloseButton (Button)

class_name Journal
extends Node2D

@export var recipe_list:      VBoxContainer
@export var ingredient_list:  VBoxContainer
@export var progress_label:   Label
@export var close_button:     Button

const LAB_SCENE := "res://scenes/Lab.tscn"

func _ready() -> void:
	if close_button:
		close_button.pressed.connect(_on_close_pressed)

	_populate_recipes()
	_populate_ingredients()
	_update_progress()

# ---------------------------------------------------------------------------
# Recipe list
# ---------------------------------------------------------------------------

func _populate_recipes() -> void:
	if not recipe_list:
		return

	var available_ids := Recipes.get_available_ids(GameState.chapter)

	for recipe_id: String in available_ids:
		var recipe: Dictionary = Recipes.db.get(recipe_id, {})
		if recipe.is_empty():
			continue

		var is_discovered := GameState.has_discovered(recipe_id)

		var card := _make_card()
		recipe_list.add_child(card)

		if is_discovered:
			var name_lbl: Label = card.get_node("NameLabel")
			var desc_lbl: Label = card.get_node("DescLabel")
			var sci_lbl: Label  = card.get_node("ScienceLabel")
			var ing_lbl: Label  = card.get_node("IngredientsLabel")

			name_lbl.text = recipe.get("display_name", "?")
			name_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))

			desc_lbl.text = recipe.get("description", "")

			var ings: Array = recipe.get("ingredients", [])
			var ing_names: Array[String] = []
			for id: String in ings:
				var def := Ingredients.get_ingredient(id)
				ing_names.append(def.get("display_name", id) if not def.is_empty() else id)
			ing_lbl.text = "Ingredients: " + " + ".join(ing_names)

			sci_lbl.text = "Science: " + recipe.get("science_note", "")
			sci_lbl.add_theme_color_override("font_color", Color(0.6, 0.9, 1.0))
		else:
			# Recipe known to exist but not yet discovered
			var name_lbl: Label = card.get_node("NameLabel")
			name_lbl.text = "??? (not yet discovered)"
			name_lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
			card.get_node("DescLabel").text = ""
			card.get_node("IngredientsLabel").text = ""
			card.get_node("ScienceLabel").text = ""

# ---------------------------------------------------------------------------
# Ingredient index
# ---------------------------------------------------------------------------

func _populate_ingredients() -> void:
	if not ingredient_list:
		return

	var available_ids := Ingredients.get_available_ids(GameState.chapter)

	for ing_id: String in available_ids:
		var def: Dictionary = Ingredients.get_ingredient(ing_id)
		if def.is_empty():
			continue

		var card := _make_card()
		ingredient_list.add_child(card)

		var name_lbl: Label = card.get_node("NameLabel")
		var desc_lbl: Label = card.get_node("DescLabel")
		var sci_lbl: Label  = card.get_node("ScienceLabel")
		var ing_lbl: Label  = card.get_node("IngredientsLabel")

		name_lbl.text = def.get("display_name", "?")
		name_lbl.add_theme_color_override("font_color", def.get("color", Color.WHITE))
		desc_lbl.text = def.get("description", "")
		sci_lbl.text  = "Science: " + def.get("science_fact", "")
		sci_lbl.add_theme_color_override("font_color", Color(0.6, 0.9, 1.0))
		ing_lbl.text  = "Found: " + def.get("growth_hint", "")

# ---------------------------------------------------------------------------
# Progress label
# ---------------------------------------------------------------------------

func _update_progress() -> void:
	if not progress_label:
		return
	var discovered := GameState.discovery_count()
	var total       := Recipes.get_available_ids(GameState.chapter).size()
	progress_label.text = "%d / %d recipes discovered (Chapter %d)" % [
		discovered, total, GameState.chapter
	]

# ---------------------------------------------------------------------------
# Card factory
## Creates a panel with four child labels for a recipe or ingredient card.
# ---------------------------------------------------------------------------

func _make_card() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 90)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	panel.add_child(vbox)

	for label_name: String in ["NameLabel", "DescLabel", "IngredientsLabel", "ScienceLabel"]:
		var lbl := Label.new()
		lbl.name = label_name
		lbl.text = ""
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(lbl)

	return panel

# ---------------------------------------------------------------------------
# Navigation
# ---------------------------------------------------------------------------

func _on_close_pressed() -> void:
	get_tree().change_scene_to_file(LAB_SCENE)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("open_journal") or event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
