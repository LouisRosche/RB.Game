# Vendor / Third-Party Modules

Place server-only third-party ModuleScripts here.
Rojo maps this folder to `ServerStorage.Vendor`.

## ProfileService Module

`ProfileService.luau` provides session-locked, auto-saving player data
persistence. DataService depends on it for all player state.

### Current Implementation

A production-ready module with cross-server session locking via
MemoryStoreService and MessagingService. Features:

- **Session locking**: MemoryStoreService SortedMap prevents data corruption
  when a player joins two servers simultaneously
- **Force-release**: MessagingService propagates session steal requests across
  servers, so the old server releases gracefully
- **Auto-save**: Every 30 seconds via RunService.Heartbeat
- **Lock refresh**: Session lock TTL refreshed every 60 seconds
- **Retry with backoff**: DataStore operations retry up to 3 times with
  exponential backoff on transient failures
- **UpdateAsync**: Uses atomic read-modify-write instead of SetAsync
- **Studio fallback**: Gracefully degrades when MemoryStore/Messaging are
  unavailable in local testing

### API Surface

```lua
local ProfileService = require(ServerStorage.Vendor.ProfileService)
local store = ProfileService.GetProfileStore("StoreName", template)
local profile = store:LoadProfileAsync("Player_" .. userId)
profile:AddUserId(userId)
profile:Reconcile()
profile:ListenToRelease(callback)
profile:Save()
profile:Release()
profile.Data -- mutable data table
profile:IsActive() -- boolean
```

### Upgrading to Official ProfileStore

If you prefer the official MadStudioRoblox implementation (recommended for
games exceeding 1,000+ CCU):

1. Download from https://madstudioroblox.github.io/ProfileStore/
2. Replace this file (`ProfileService.luau`) — the API is compatible
3. ProfileStore offers: 10x fewer DataStore calls (300s auto-save),
   better error handling, Luau types for autocompletion
