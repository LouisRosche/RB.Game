# Potion Lab — Roblox Game (Phase 1-2)

An idle tycoon where players grow magical ingredients, brew potions at a cauldron, and upgrade their lab. Built with Single-Script Architecture and Rojo.

## Getting Started

### Prerequisites

1. **Roblox Studio** — [Download](https://www.roblox.com/create)
2. **Aftman** (toolchain manager) — install then run:
   ```sh
   aftman init
   aftman add rojo-rbx/rojo
   aftman install
   ```
3. Or install **Rojo** directly:
   ```sh
   # via cargo
   cargo install rojo
   # or download from https://github.com/rojo-rbx/rojo/releases
   ```
4. Install the **Rojo plugin** in Roblox Studio (Plugins → Manage Plugins → search "Rojo")

### Running the game

```sh
cd roblox/
rojo serve default.project.json
```

Then in Roblox Studio:
1. Open a new place
2. Click the Rojo plugin → "Connect" (localhost:34872)
3. Files sync automatically — hit Play to test

### Project structure

```
roblox/
├── default.project.json          Rojo config (maps src/ → Roblox services)
├── src/
│   ├── server/
│   │   ├── Main.server.luau      Single server entry point
│   │   └── Services/
│   │       ├── DataService.luau      Player data (load/save/sync)
│   │       ├── PlotService.luau      3D lab creation & plot visuals
│   │       ├── GrowthService.luau    Plant growth ticking & mutations
│   │       ├── BrewingService.luau   Potion crafting logic
│   │       └── EconomyService.luau   Gold transactions & upgrades
│   ├── client/
│   │   ├── Main.client.luau      Single client entry point
│   │   └── Controllers/
│   │       ├── UIController.luau         All UI (HUD, shop, brewing, sell)
│   │       └── InteractionController.luau ProximityPrompt handling
│   └── shared/
│       ├── Config.luau           Game balance constants (single source of truth)
│       ├── Ingredients.luau      4 ingredient definitions
│       ├── Recipes.luau          10 potion recipes + value calculator
│       ├── Network.luau          RemoteEvent name constants
│       └── Strings.luau          All player-facing text (i18n-ready)
└── assets/                       Art, sound, UI assets (future)
```

## Architecture

Uses **Single-Script Architecture** (the pattern behind Adopt Me, Brookhaven, and other front-page games):

- `Main.server.luau` — boots all services, creates RemoteEvents, routes client requests
- `Main.client.luau` — boots controllers, listens for state sync and notifications
- **Server-authoritative** — all game logic runs on the server; client is display-only
- **Full state sync** — server pushes complete player state after every action

### Data flow

```
Player clicks plot → ProximityPrompt triggers
  → InteractionController → fires RemoteEvent
    → Main.server.luau routes to GrowthService.plantSeed()
      → validates input, deducts gold, updates plot state
        → PlotService.updatePlotVisual() (3D world)
        → DataService.syncToClient() (full state push)
          → UIController.updateState() (refresh UI)
```

## Key Technical Rules

1. **Never** use `Players.LocalPlayer` in server scripts
2. **Always** use `WaitForChild()` for replicated objects
3. **Always** use `task.wait()` instead of deprecated `wait()`
4. **Always** wrap DataStore calls in `pcall()`
5. **Always** disconnect event connections to prevent memory leaks
6. **Never** import Free Models without inspecting for backdoor scripts
7. All player-facing strings go in `Strings.luau` (i18n-ready)
8. All balance tuning goes in `Config.luau` (one place to change numbers)

## Performance Targets

- Part count: < 75,000
- StreamingEnabled: ON
- MeshPart RenderFidelity: "Automatic"
- All stationary parts: anchored
- Target devices: mobile (low-end) through desktop

## Monetization (Phase 2 — not in vertical slice)

- Cosmetic shop: lab decorations, cauldron skins, potion bottle styles
- Game passes: 2x growth speed, auto-harvest, VIP lab theme
- Optional seasonal battle pass with dual-track free/premium
- No loot boxes, no pay-to-win, no gambling mechanics

## Retention Targets

| Metric | Minimum | Target | Excellent |
|--------|---------|--------|-----------|
| D1 Retention | 20% | 30% | 40%+ |
| D7 Retention | 5% | 10% | 15%+ |
| Session Length | 8 min | 15 min | 25+ min |
