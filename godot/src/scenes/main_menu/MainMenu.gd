## MainMenu.gd
## Attached to: res://scenes/MainMenu.tscn
##
## Scene node structure (create in Godot editor):
##   MainMenu (Node2D)
##     Background (ColorRect)          -- fills viewport, deep purple
##     TitleLabel (Label)              -- "ALCHEMY ACADEMY\nOrigins"
##     SubtitleLabel (Label)           -- "A narrative alchemy puzzle game"
##     ButtonContainer (VBoxContainer)
##       NewGameButton (Button)
##       ContinueButton (Button)
##       SettingsButton (Button)
##       QuitButton (Button)
##     VersionLabel (Label)            -- bottom-right, "v0.1.0"
##
## All @export references are wired in the editor.

class_name MainMenu
extends Node2D

# ---------------------------------------------------------------------------
# Node references (wire in editor via @export or $NodePath)
# ---------------------------------------------------------------------------

@export var new_game_button:    Button
@export var continue_button:    Button
@export var settings_button:    Button
@export var quit_button:        Button
@export var title_label:        Label
@export var version_label:      Label

## Path to Lab scene (main gameplay)
const LAB_SCENE     := "res://scenes/Lab.tscn"
const SETTINGS_SCENE := "res://scenes/Settings.tscn"

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	_setup_buttons()
	_update_continue_visibility()

	if title_label:
		title_label.text = "ALCHEMY ACADEMY\nOrigins"
	if version_label:
		version_label.text = ProjectSettings.get_setting("application/config/version", "")

func _update_continue_visibility() -> void:
	if continue_button:
		continue_button.visible = SaveManager.has_save()

# ---------------------------------------------------------------------------
# Button wiring
# ---------------------------------------------------------------------------

func _setup_buttons() -> void:
	if new_game_button:
		new_game_button.pressed.connect(_on_new_game_pressed)
	if continue_button:
		continue_button.pressed.connect(_on_continue_pressed)
	if settings_button:
		settings_button.pressed.connect(_on_settings_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)

func _on_new_game_pressed() -> void:
	if SaveManager.has_save():
		# In production: show a confirmation dialog before wiping the save.
		# For MVP just overwrite.
		pass
	GameState.new_game()
	SaveManager.save_game()
	get_tree().change_scene_to_file(LAB_SCENE)

func _on_continue_pressed() -> void:
	# Data was already loaded by SaveManager._ready(); just navigate.
	get_tree().change_scene_to_file(LAB_SCENE)

func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file(SETTINGS_SCENE)

func _on_quit_pressed() -> void:
	SaveManager.save_game()
	get_tree().quit()

# ---------------------------------------------------------------------------
# Input
# ---------------------------------------------------------------------------

func _input(event: InputEvent) -> void:
	# Allow Escape to quit from main menu
	if event.is_action_pressed("ui_cancel"):
		_on_quit_pressed()
