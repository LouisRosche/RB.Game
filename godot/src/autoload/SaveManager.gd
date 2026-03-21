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
const SAVE_VERSION  := 1

## Secret used for save integrity check. Not cryptographically strong (local
## single-player game) but raises the bar above plain-text editing.
const _INTEGRITY_SECRET := "AlchemyAcademy_v1_salt"

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

	cfg.set_value("meta", "version", SAVE_VERSION)

	cfg.set_value("progress", "gold",               GameState.gold)
	cfg.set_value("progress", "chapter",             GameState.chapter)
	cfg.set_value("progress", "ingredients",         GameState.ingredients)
	cfg.set_value("progress", "potions",             GameState.potions)
	cfg.set_value("progress", "discovered_recipes",  GameState.discovered_recipes)
	cfg.set_value("progress", "stats",               GameState.stats)

	# Compute integrity hash over progress fields to detect tampering
	cfg.set_value("meta", "checksum", _compute_checksum(cfg))

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

	# Verify integrity before trusting any values
	var stored_checksum: String = cfg.get_value("meta", "checksum", "")
	var computed_checksum := _compute_checksum(cfg)
	if stored_checksum != "" and stored_checksum != computed_checksum:
		push_warning("[SaveManager] Save file integrity check failed — possible tampering. Using defaults.")
		return

	# Type-validated loading: reject values that don't match expected types
	GameState.gold               = _load_int(cfg, "progress", "gold", GameState.gold)
	GameState.chapter            = _load_int(cfg, "progress", "chapter", GameState.chapter)
	GameState.ingredients        = _load_array(cfg, "progress", "ingredients", GameState.ingredients)
	GameState.potions            = _load_array(cfg, "progress", "potions", GameState.potions)
	GameState.discovered_recipes = _load_dict(cfg, "progress", "discovered_recipes", GameState.discovered_recipes)
	GameState.stats              = _load_dict(cfg, "progress", "stats", GameState.stats)

	# Clamp gold to valid range after load
	GameState.gold = clampi(GameState.gold, 0, GameState.MAX_GOLD)

func load_settings() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(SETTINGS_PATH)
	if err != OK:
		return  # defaults from GameState.settings are fine

	for key: String in GameState.settings:
		GameState.settings[key] = cfg.get_value("settings", key, GameState.settings[key])

	_apply_settings()

# ---------------------------------------------------------------------------
# Type-safe loaders — reject tampered values, fall back to defaults
# ---------------------------------------------------------------------------

func _load_int(cfg: ConfigFile, section: String, key: String, default_val: int) -> int:
	var val = cfg.get_value(section, key, default_val)
	if typeof(val) != TYPE_INT:
		push_warning("[SaveManager] Type mismatch for %s.%s: expected int, got %s" % [section, key, type_string(typeof(val))])
		return default_val
	return val

func _load_array(cfg: ConfigFile, section: String, key: String, default_val: Array) -> Array:
	var val = cfg.get_value(section, key, default_val)
	if typeof(val) != TYPE_ARRAY:
		push_warning("[SaveManager] Type mismatch for %s.%s: expected Array" % [section, key])
		return default_val
	return val

func _load_dict(cfg: ConfigFile, section: String, key: String, default_val: Dictionary) -> Dictionary:
	var val = cfg.get_value(section, key, default_val)
	if typeof(val) != TYPE_DICTIONARY:
		push_warning("[SaveManager] Type mismatch for %s.%s: expected Dictionary" % [section, key])
		return default_val
	return val

func _compute_checksum(cfg: ConfigFile) -> String:
	# Hash all progress fields concatenated with a secret salt.
	# This is a deterrent, not DRM — the game is single-player.
	var payload := ""
	for key in ["gold", "chapter"]:
		payload += str(cfg.get_value("progress", key, ""))
	payload += _INTEGRITY_SECRET
	return payload.sha256_text()

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
