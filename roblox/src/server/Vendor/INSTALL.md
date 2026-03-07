# Vendor / Third-Party Modules

Place server-only third-party ModuleScripts here.
Rojo maps this folder to `ServerStorage.Vendor`.

## Required: ProfileService

DataService depends on ProfileService for session-locked, auto-saving
player data persistence (CLAUDE.md: "never raw DataStoreService").

**Install steps:**
1. Go to https://github.com/MadStudioRoblox/ProfileService/releases
2. Download the latest `ProfileService.lua` (or `.luau`)
3. Save it as `roblox/src/server/Vendor/ProfileService.luau`

That's it — Rojo will sync it to `ServerStorage.Vendor.ProfileService`
and DataService will pick it up via:
```lua
require(ServerStorage:WaitForChild("Vendor"):WaitForChild("ProfileService"))
```

ProfileService is intentionally excluded from this repo (it has its own
MIT license and its own release cycle). Pin the version you use by
noting it here:

**Pinned version:** STUB (development only — replace before production launch)

A compatibility stub is currently installed at `ProfileService.luau`.
It covers the full API surface used by DataService (GetProfileStore,
LoadProfileAsync, AddUserId, Reconcile, ListenToRelease, Release, Save)
with DataStoreService-backed persistence, so Studio playtesting works
immediately without any extra setup.

**The stub lacks cross-server session locking.** Replace it with the real
ProfileService before your first public launch to prevent data corruption
on simultaneous joins from the same account.
