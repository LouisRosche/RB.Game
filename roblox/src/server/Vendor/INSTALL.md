# Vendor / Third-Party Modules

Place server-only third-party ModuleScripts here.
Rojo maps this folder to `ServerStorage.Vendor`.

## CRITICAL: Replace ProfileService Stub Before Launch

DataService depends on ProfileService/ProfileStore for session-locked,
auto-saving player data persistence (CLAUDE.md: "never raw DataStoreService").

### Recommended: ProfileStore (2026 successor to ProfileService)

As of 2025-2026, **ProfileStore** is the actively maintained successor to
ProfileService by the same author (MadStudioRoblox). Key improvements:

- 10x fewer DataStore calls (auto-save 300s vs 30s)
- MessagingService integration for faster session lock resolution
- Better error handling with exponential backoff
- Luau types for autocompletion
- Backwards-compatible with ProfileService DataStore keys

**Install ProfileStore (recommended for new projects):**
1. Go to https://madstudioroblox.github.io/ProfileStore/
2. Download the latest ModuleScript
3. Save it as `roblox/src/server/Vendor/ProfileService.luau` (same filename — API is compatible)
4. Update any API calls if needed (function names are slightly different)

**Or install ProfileService (still works, less actively maintained):**
1. Go to https://github.com/MadStudioRoblox/ProfileService/releases
2. Download the latest `ProfileService.lua` (or `.luau`)
3. Save it as `roblox/src/server/Vendor/ProfileService.luau`

Either library will be picked up by DataService via:
```lua
require(ServerStorage:WaitForChild("Vendor"):WaitForChild("ProfileService"))
```

**Pinned version:** STUB (development only — MUST REPLACE before any real players)

A compatibility stub is currently installed at `ProfileService.luau`.
It covers the full API surface used by DataService (GetProfileStore,
LoadProfileAsync, AddUserId, Reconcile, ListenToRelease, Release, Save)
with DataStoreService-backed persistence, so Studio playtesting works
immediately without any extra setup.

**WARNING: The stub lacks cross-server session locking.** Without the real
library, players can duplicate items and currency by joining two servers
simultaneously. This is a CRITICAL data integrity vulnerability. Replace
the stub before your first public (or even unlisted) launch.
