## Settings.gd
## Attached to: res://scenes/Settings.tscn
## Volume controls, fullscreen toggle, and key rebinding hints.
##
## Scene node structure (create in Godot editor):
##   Settings (Node2D)
##     Background (ColorRect)
##     Header (Label)                 -- "Settings"
##     MasterSlider (HSlider)         -- 0.0–1.0
##     MasterLabel (Label)            -- "Master Volume: 80%"
##     SFXSlider (HSlider)
##     SFXLabel (Label)
##     MusicSlider (HSlider)
##     MusicLabel (Label)
##     FullscreenCheck (CheckButton)  -- "Fullscreen"
##     BackButton (Button)
##     DeleteSaveButton (Button)      -- danger zone, shows confirm dialog

class_name Settings
extends Node2D

@export var master_slider:       HSlider
@export var master_label:        Label
@export var sfx_slider:          HSlider
@export var sfx_label:           Label
@export var music_slider:        HSlider
@export var music_label:         Label
@export var fullscreen_check:    CheckButton
@export var back_button:         Button
@export var delete_save_button:  Button

## Previous scene path so "Back" returns where the player came from.
## Set by the scene that opens Settings (e.g. Lab.gd).
## Default: return to MainMenu.
var return_scene := "res://scenes/MainMenu.tscn"

func _ready() -> void:
	_load_current_settings()
	_connect_signals()

# ---------------------------------------------------------------------------
# Load settings into UI
# ---------------------------------------------------------------------------

func _load_current_settings() -> void:
	var s := GameState.settings

	if master_slider:
		master_slider.value = s.get("master_volume", 1.0)
	if sfx_slider:
		sfx_slider.value = s.get("sfx_volume", 0.8)
	if music_slider:
		music_slider.value = s.get("music_volume", 0.4)
	if fullscreen_check:
		fullscreen_check.button_pressed = s.get("fullscreen", false)

	_update_labels()

func _update_labels() -> void:
	if master_label and master_slider:
		master_label.text = "Master Volume: %d%%" % int(master_slider.value * 100)
	if sfx_label and sfx_slider:
		sfx_label.text = "SFX Volume: %d%%" % int(sfx_slider.value * 100)
	if music_label and music_slider:
		music_label.text = "Music Volume: %d%%" % int(music_slider.value * 100)

# ---------------------------------------------------------------------------
# Signal connections
# ---------------------------------------------------------------------------

func _connect_signals() -> void:
	if master_slider:
		master_slider.value_changed.connect(_on_master_changed)
	if sfx_slider:
		sfx_slider.value_changed.connect(_on_sfx_changed)
	if music_slider:
		music_slider.value_changed.connect(_on_music_changed)
	if fullscreen_check:
		fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	if delete_save_button:
		delete_save_button.pressed.connect(_on_delete_save_pressed)

# ---------------------------------------------------------------------------
# Handlers
# ---------------------------------------------------------------------------

func _on_master_changed(value: float) -> void:
	GameState.settings["master_volume"] = value
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Master"),
		linear_to_db(value)
	)
	_update_labels()

func _on_sfx_changed(value: float) -> void:
	GameState.settings["sfx_volume"] = value
	# SFX bus: adjust here once a separate SFX bus is set up in the audio layout
	_update_labels()

func _on_music_changed(value: float) -> void:
	GameState.settings["music_volume"] = value
	# Music bus: adjust here once a Music bus is set up in the audio layout
	_update_labels()

func _on_fullscreen_toggled(toggled: bool) -> void:
	GameState.settings["fullscreen"] = toggled
	if toggled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_back_pressed() -> void:
	SaveManager.save_settings()
	get_tree().change_scene_to_file(return_scene)

func _on_delete_save_pressed() -> void:
	# Production: show a confirmation dialog (AcceptDialog) first.
	# MVP: delete immediately.
	SaveManager.delete_save()
	GameState.new_game()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
