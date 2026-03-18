# Alchemy Academy: Origins — Godot 4 Standalone Game

A narrative puzzle-adventure set in the same universe as the Roblox game.
Built with Godot 4 + GDScript. Target platforms: Steam (Windows/macOS/Linux),
Epic Games Store, itch.io. One-time purchase, no DLC, no microtransactions.

---

## Concept

**Alchemy Academy: Origins** is a story-driven puzzle game where you play as a
new student who discovers the Academy's secrets by experimenting with 10 unique
ingredients across 4 chapters. Every recipe you unlock reveals a real science
fact — from nuclear fusion to mycorrhizal networks.

**Different from the Roblox game:**
- Linear narrative chapters (not open-ended idle)
- 10 base ingredients + 6 exclusive to this game (vs. 4 in Roblox)
- 15 recipes to discover (vs. 10)
- 3–5 hours of content with a proper ending
- Offline, no internet required

---

## Dev Environment Setup

### 1. Install Godot 4

Download **Godot 4.3+** (Standard, not Mono) from https://godotengine.org/download

> The `.NET / C#` version is not required — all code is GDScript.

### 2. Open the project

```
File → Open → select /godot/project.godot
```

Godot will import assets and generate the `.godot/` folder automatically.

### 3. Wire @export references

Scene files (`.tscn`) are committed with full node hierarchies and scripts attached.
Open each scene in the editor and wire the `@export` variables by selecting the root
node and dragging child nodes into the export slots in the **Inspector**.

See `scenes/SCENE_STRUCTURE.md` for the mapping of which node goes to which export.

### 4. Run the game

Press **F5** or click the Play button. The entry point is `res://scenes/MainMenu.tscn`
(set in `project.godot → application/run/main_scene`).

---

## Project Structure

```
godot/
  project.godot              ← Godot project config (autoloads, display settings)
  src/
    autoload/
      GameState.gd           ← Singleton: all in-session player data + signals
      SaveManager.gd         ← Singleton: save/load via ConfigFile (user://save.cfg)
      Ingredients.gd         ← Singleton: ingredient database (10 ingredients)
      Recipes.gd             ← Singleton: recipe database (15 recipes) + lookup
    scenes/
      main_menu/
        MainMenu.gd          ← Main menu: New Game / Continue / Settings / Quit
      lab/
        Lab.gd               ← Core gameplay: select ingredients, brew, sell
      journal/
        Journal.gd           ← Recipe book + ingredient science facts
      settings/
        Settings.gd          ← Volume, fullscreen, delete save
  scenes/
    SCENE_STRUCTURE.md       ← Scene tree reference (node → @export mapping)
    MainMenu.tscn            ← Main menu scene
    Lab.tscn                 ← Core gameplay scene
    Journal.tscn             ← Recipe book / ingredient index
    Settings.tscn            ← Audio / display settings
  assets/
    (art, sounds, fonts — to be added)
```

---

## Architecture

### Autoloads (singletons)

Registered in `project.godot [autoload]` and accessible from any script globally.

| Singleton | Purpose |
|-----------|---------|
| `GameState` | Source of truth for all player data. Emits `state_changed` and `recipe_discovered` signals. |
| `SaveManager` | Serialises `GameState` to `user://save.cfg` via ConfigFile. Loaded on startup. |
| `Ingredients` | Read-only ingredient database. Keyed by string id. |
| `Recipes` | Read-only recipe database. `lookup(id_a, id_b)` returns a recipe dict or `{}`. |

### Scene navigation

All scene transitions use `get_tree().change_scene_to_file("res://scenes/X.tscn")`.
There is no scene stack — navigating always replaces the current scene.

### Save format

`user://save.cfg` — Godot ConfigFile (INI-like, human-readable):
```
[progress]
gold=150
chapter=1
ingredients=[{"id":"moonpetal","rarity":"Rare"}]
...
```

`user://settings.cfg` — separate file so settings survive "New Game":
```
[settings]
master_volume=1.0
fullscreen=false
```

---

## Ingredient & Recipe Data

All data lives in the autoload singletons (not JSON files) so Godot's type
system can help catch typos. To add an ingredient:

1. Call `_register({...})` in `Ingredients.gd._register_all()`
2. Add the matching recipes in `Recipes.gd._register_all()`
3. Set the `chapter` field to control when it becomes available

---

## Steam / Export Setup (Phase 3 Week 41+)

1. **Export templates**: Editor → Manage Export Templates → Download 4.3 stable
2. **Windows**: Project → Export → Add Windows Desktop preset → Export
3. **macOS**: Requires an Apple developer certificate for notarisation
4. **Linux**: Export as `.x86_64` binary (Steam Deck compatible)
5. **Steamworks SDK**: Integrate via the GodotSteam plugin (MIT licence)
   - https://godotsteam.com/ — pre-built binaries available
   - Required for Steam Cloud saves, achievements, and trading cards
6. **AppID**: Register at https://partner.steamgames.com ($100 one-time fee)

---

## Development Roadmap

| Milestone | Target | Status |
|-----------|--------|--------|
| Core loop working in editor | Week 41 | Scripts + scenes done — wire @exports |
| Chapter 1 complete + playable | Week 43 | ⬜ |
| All 4 chapters complete | Week 50 | ⬜ |
| Art pass (placeholder → real) | Week 52 | ⬜ |
| Steam store page live | Week 45 | ⬜ |
| Steam Next Fest demo | Week 60 | ⬜ |
| Launch (7K+ wishlists) | Week 72 | ⬜ |
| Localisation: zh-CN, de, pt-BR | Week 74 | ⬜ |

---

## Anti-Dark-Pattern Design (same rules as Roblox game)

- One-time purchase — no DLC, no season passes, no microtransactions
- All science facts are real and cited in the in-game Journal
- No artificial time pressure or energy systems
- Game can be completed without any internet connection
- All save data stored locally; Steamworks Cloud is opt-in additive

---

## Why This Game Is Different from the Roblox Version

| Feature | Roblox (Alchemy Academy) | Godot (Origins) |
|---------|--------------------------|-----------------|
| Genre | Idle tycoon / simulator | Narrative puzzle-adventure |
| Length | Ongoing (no ending) | 3–5 hours + ending |
| Multiplayer | Yes (leaderboards, co-presence) | No (singleplayer) |
| Revenue model | Free + cosmetics + passes | One-time purchase |
| Platform | Roblox only | Steam, Epic, itch.io, mobile |
| Unique ingredients | 4 | 10 |
| Unique recipes | 10 | 15 |
| Narrative | None | 4-chapter story |
