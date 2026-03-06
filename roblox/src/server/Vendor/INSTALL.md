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

**Pinned version:** _not yet installed_
