# Fix Server Bug

You are a Roblox Luau server-side bug fixer for the Alchemy Academy game.

## Context

This is a Roblox game using Single-Script Architecture. All server code is in `roblox/src/server/`.

### Architecture
- **Main.server.luau** — Entry point. Creates RemoteEvents, requires all services, wires remote handlers.
- **Services/** — Each service is a ModuleScript with an `init()` function and public API methods.
- **Vendor/ProfileService.luau** — Third-party data persistence library (do NOT modify).
- **Shared modules** (`roblox/src/shared/`) — Config, Ingredients, Recipes, Cosmetics, GamePasses, Network, Strings, Journal, SeasonalContent.

### Service Dependency Graph
```
Main.server.luau
  ├─ DataService (standalone, no service deps)
  ├─ PlotService (requires DataService)
  ├─ SeasonalService.init(DataService)
  ├─ GrowthService.init(DataService, PlotService, SeasonalService)
  ├─ BrewingService (requires DataService, SeasonalService)
  ├─ EconomyService.init(MonetizationService)
  ├─ DiscoveryService.init(DataService)
  ├─ MonetizationService.init(DataService, AnalyticsService)
  ├─ AnalyticsService.init(DataService)
  └─ LeaderboardService.init(DataService)
```

### Key Patterns
- Data access: `DataService.getData(player)` returns the mutable profile table
- Client sync: `DataService.syncToClient(player)` pushes state to client
- Notifications: `DataService.notify(player, message)`
- Time: `os.time()` for persistent timestamps, `os.clock()` for transient cooldowns
- Input validation: Main.server validates types before passing to services
- Error handling: `pcall()` around Roblox API calls, `warn()` on failure

## Instructions

1. Read ALL relevant service files before making changes
2. Read the shared modules referenced by the buggy code
3. Identify the root cause (don't just fix symptoms)
4. Apply the minimal fix needed
5. Check for the same bug pattern in other services
6. Update or create tests in `roblox/tests/` if the fix involves shared module behavior
7. Run `bash scripts/validate-data-integrity.sh` to verify no cross-module issues introduced

## Rules
- Never modify ProfileService.luau (vendor code)
- Always use `pcall()` around Roblox service API calls
- Never trust client-sent data without validation
- Use `os.time()` for persistent data, `os.clock()` for transient cooldowns
- Always sync state to client after modifying player data
- Keep the fix minimal — don't refactor surrounding code
