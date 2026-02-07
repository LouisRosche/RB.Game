# Roblox Game (Phase 1-2)

## Architecture

Uses **Single-Script Architecture** (the pattern behind Adopt Me, Brookhaven, and other front-page games):

- `src/server/` — One main ServerScript that `require()`s ModuleScripts for all server-side logic
- `src/client/` — One main LocalScript that `require()`s ModuleScripts for all client-side logic
- `src/shared/` — ModuleScripts shared between server and client (via ReplicatedStorage)
- `assets/` — Art, sound, and UI assets

## Key Technical Rules

1. **Never** use `Players.LocalPlayer` in server scripts
2. **Always** use `WaitForChild()` for replicated objects
3. **Always** use `task.wait()` instead of deprecated `wait()`
4. **Always** wrap DataStore calls in `pcall()`
5. **Always** disconnect event connections to prevent memory leaks
6. **Never** import Free Models without inspecting for backdoor scripts
7. Use ProfileService/ProfileStore for data persistence — never raw DataStoreService

## Performance Targets

- Part count: < 75,000
- StreamingEnabled: ON
- MeshPart RenderFidelity: "Automatic"
- All stationary parts: anchored
- Target devices: mobile (low-end) through desktop

## Monetization (Phase 2)

- Cosmetic shop: 10-15 items, 50-500 Robux ($0.63-$6.25)
- Game passes: 2-3 convenience passes (2x speed, auto-collect, VIP)
- Optional seasonal battle pass with dual-track free/premium
- No loot boxes, no pay-to-win, no gambling mechanics

## Retention Targets

| Metric | Minimum | Target | Excellent |
|--------|---------|--------|-----------|
| D1 Retention | 20% | 30% | 40%+ |
| D7 Retention | 5% | 10% | 15%+ |
| Session Length | 8 min | 15 min | 25+ min |
