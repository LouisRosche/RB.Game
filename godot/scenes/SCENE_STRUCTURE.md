# Scene Structure — Alchemy Academy: Origins

This file documents the scene tree layout and the mapping between scene nodes
and `@export` variables. Scene files (`.tscn`) are committed with node
hierarchies and scripts attached. Open each scene in the Godot editor and
wire the `@export` references by dragging nodes into the Inspector slots.

---

## MainMenu.tscn

```
MainMenu (Node2D)  ← attach MainMenu.gd
  Background (ColorRect)
    [full-viewport, Color #1a1228]
  TitleLabel (Label)
    [text: "ALCHEMY ACADEMY\nOrigins", centered, large font]
  SubtitleLabel (Label)
    [text: "A narrative alchemy puzzle game"]
  ButtonContainer (VBoxContainer)
    [anchored center-screen]
    NewGameButton (Button)   → @export new_game_button
    ContinueButton (Button)  → @export continue_button
    SettingsButton (Button)  → @export settings_button
    QuitButton (Button)      → @export quit_button
  VersionLabel (Label)       → @export version_label
    [anchored bottom-right]
```

---

## Lab.tscn

```
Lab (Node2D)  ← attach Lab.gd
  Background (ColorRect)
    [full-viewport, Color #1a1228]
  HUD (CanvasLayer)
    GoldLabel (Label)         → @export gold_label
      [top-left: "Essence: 100"]
    ChapterLabel (Label)      → @export chapter_label
      [top-center: "Chapter 1: The Newcomer"]
    JournalButton (Button)
      [top-right: "Journal (J)"]
      [Pressed → change_scene Journal.tscn]
    MenuButton (Button)
      [Pressed → save + change_scene MainMenu.tscn]
  IngredientPanel (Panel)
    [left half of screen]
    PanelHeader (Label)      ["Ingredients"]
    IngredientScroll (ScrollContainer)
      IngredientList (VBoxContainer)  → @export ingredient_list
  CauldronArea (Node2D)
    [center-top]
    CauldronRect (ColorRect)
      [placeholder: 120×120 dark purple square]
    SelectionLabel (Label)   → @export selection_label
      ["Select 2 ingredients to brew."]
    BrewButton (Button)      → @export brew_button
      ["Brew"]
  PotionPanel (Panel)
    [right half of screen]
    PanelHeader (Label)      ["Potions"]
    PotionScroll (ScrollContainer)
      PotionList (VBoxContainer)  → @export potion_list
    SellAllButton (Button)   → @export sell_all_button
      ["Sell All"]
  DiscoveryOverlay (CanvasLayer)   → @export discovery_overlay
    [Visible = false by default]
    OverlayBackground (ColorRect)
      [semi-transparent black, full-viewport]
    DiscoveryLabel (Label)   → @export discovery_label
      [centered, large gold text]
    ScienceLabel (Label)     → @export science_label
      [centered, blue text, autowrap]
    CloseButton (Button)     → @export overlay_close_btn
      ["Continue"]
  Notification (Label)       → @export notification_label
    [top-center, hidden by default, autowrap]
```

---

## Journal.tscn

```
Journal (Node2D)  ← attach Journal.gd
  Background (ColorRect)
    [full-viewport, Color #0f0c1a]
  Header (Label)
    ["Alchemist's Journal"]
  ProgressLabel (Label)   → @export progress_label
    [below header]
  TabContainer (TabContainer)
    RecipesTab (ScrollContainer)
      [Tab name: "Recipes"]
      RecipeList (VBoxContainer)   → @export recipe_list
    IngredientsTab (ScrollContainer)
      [Tab name: "Ingredients"]
      IngredientList (VBoxContainer)   → @export ingredient_list
  CloseButton (Button)   → @export close_button
    [bottom or top-right: "Close (J / Esc)"]
```

---

## Settings.tscn

```
Settings (Node2D)  ← attach Settings.gd
  Background (ColorRect)
  Header (Label) ["Settings"]
  MasterLabel (Label)      → @export master_label
  MasterSlider (HSlider)   → @export master_slider   [min=0, max=1, step=0.01]
  SFXLabel (Label)         → @export sfx_label
  SFXSlider (HSlider)      → @export sfx_slider
  MusicLabel (Label)       → @export music_label
  MusicSlider (HSlider)    → @export music_slider
  FullscreenCheck (CheckButton)  → @export fullscreen_check
  BackButton (Button)      → @export back_button  ["Back"]
  DeleteSaveButton (Button) → @export delete_save_button  ["Delete Save (Danger)"]
    [red background to indicate destructive action]
```

---

## Placeholder art guide

Until real assets are created, use ColorRect nodes for all visuals:

| Element          | Color              |
|------------------|--------------------|
| Background       | #1a1228 (deep purple) |
| Cauldron         | #3d1a6e (violet)   |
| HUD panel        | #251840 (dark purple) |
| Common item      | #c0c0c0 (silver)   |
| Uncommon item    | #00c800 (green)    |
| Rare item        | #0064ff (blue)     |
| Epic item        | #9900ff (purple)   |
| Legendary item   | #ffd700 (gold)     |

---

## Adding a new scene to autoload

Do NOT add scenes to autoload. Only scripts that extend Node and are
registered in `project.godot [autoload]` are singletons.
All game scenes go in `res://scenes/` and are loaded via
`get_tree().change_scene_to_file("res://scenes/MyScene.tscn")`.
