## SaveManager.gd
## Autoload singleton — handles save / load using Godot's ConfigFile.
##
## Save file: user://save.cfg  (platform-native AppData / .local path)
## Settings:  user://settings.cfg  (separate so settings survive new games)
##
## Format: ConfigFile (INI-like, human-readable, built-in — no plugins needed)
##
## Key design decisions:
##   - Save is idempotent: calling save() twice is always safe
##   - Load failures default to GameState initial values (no crash on missing file)
##   - Settings are saved separately so "New Game" doesn't wipe volume/fullscreen
##   - No cloud save in MVP; Steamworks Cloud can be added in Phase 3 launch week

extends Node

const SAVE_PATH     := "user://save.cfg"
const SETTINGS_PATH := "user://settings.cfg"

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	load_settings()
	load_game()

# ---------------------------------------------------------------------------
# Save
# ---------------------------------------------------------------------------

func save_game() -> void:
	var cfg := ConfigFile.new()

	cfg.set_value("progress", "gold",               GameState.gold)
	cfg.set_value("progress", "chapter",             GameState.chapter)
	cfg.set_value("progress", "ingredients",         GameState.ingredients)
	cfg.set_value("progress", "potions",             GameState.potions)
	cfg.set_value("progress", "discovered_recipes",  GameState.discovered_recipes)
	cfg.set_value("progress", "stats",               GameState.stats)

	var err := cfg.save(SAVE_PATH)
	if err != OK:
		push_warning("[SaveManager] Failed to save game: error %d" % err)

func save_settings() -> void:
	var cfg := ConfigFile.new()
	for key: String in GameState.settings:
		cfg.set_value("settings", key, GameState.settings[key])
	var err := cfg.save(SETTINGS_PATH)
	if err != OK:
		push_warning("[SaveManager] Failed to save settings: error %d" % err)

# ---------------------------------------------------------------------------
# Load
# ---------------------------------------------------------------------------

func load_game() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(SAVE_PATH)
	if err != OK:
		# First run or save file missing — defaults from GameState are fine
		return

	GameState.gold               = cfg.get_value("progress", "gold",               GameState.gold)
	GameState.chapter            = cfg.get_value("progress", "chapter",             GameState.chapter)
	GameState.ingredients        = cfg.get_value("progress", "ingredients",         GameState.ingredients)
	GameState.potions            = cfg.get_value("progress", "potions",             GameState.potions)
	GameState.discovered_recipes = cfg.get_value("progress", "discovered_recipes",  GameState.discovered_recipes)
	GameState.stats              = cfg.get_value("progress", "stats",               GameState.stats)

func load_settings() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(SETTINGS_PATH)
	if err != OK:
		return  # defaults from GameState.settings are fine

	for key: String in GameState.settings:
		GameState.settings[key] = cfg.get_value("settings", key, GameState.settings[key])

	_apply_settings()

# ---------------------------------------------------------------------------
# Apply settings immediately after loading
# ---------------------------------------------------------------------------

func _apply_settings() -> void:
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Master"),
		linear_to_db(GameState.settings.get("master_volume", 1.0))
	)
	if GameState.settings.get("fullscreen", false):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

# ---------------------------------------------------------------------------
# Public helpers
# ---------------------------------------------------------------------------

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func delete_save() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
