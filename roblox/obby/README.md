# Obby — Quick-Release Revenue Game

A production-ready obby (obstacle course) designed for quick release and sustained
revenue. Solo obby devs on Roblox report $20-27K/month. This game also serves as
a cross-promotion funnel for the main **Alchemy Academy** tycoon game.

---

## Features

### Core Gameplay
- **40-stage obstacle course** (World 1) with checkpoint save/load via DataStoreService
- **Coin collection** — coins scattered across platforms, server-authoritative to prevent exploits
- **Death counter** — tracks per-session deaths
- **Speedrun timer** — starts on first real checkpoint, stops on completion
- **Fastest-time leaderboard** — OrderedDataStore, top 10 displayed

### Monetization
| Product | Type | Price | Description |
|---------|------|-------|-------------|
| Skip Stage | Developer Product (consumable) | 50 R$ | Advances player to the next checkpoint instantly |
| VIP Pass | Game Pass (permanent) | 200 R$ | Speed boost (+20 WalkSpeed), 2x coin earnings, gold VIP chat tag |

**Design principle:** cosmetics and convenience only — no pay-to-win, no loot boxes.

### Cross-Promotion
- After completing World 1, players see a banner prompting them to play **Alchemy Academy**
- Server-authoritative teleport via TeleportService
- Configurable place ID in `Config.luau`

### Client HUD
- Stage counter (X / 40) with timer
- Coin counter (gold text)
- Death counter (red text)
- VIP badge (shown when VIP pass owned)
- Shop button with skip-stage and VIP purchase options
- Completion overlay with time, best time, and session stats
- Cross-promo banner with "Play Now" and "Later" buttons

---

## Architecture

Single-Script Architecture (one ServerScript + one LocalScript + shared ModuleScripts).

```
obby/
├── default.project.json              Rojo config
└── src/
    ├── server/Main.server.luau       All server systems (checkpoints, coins, monetization, leaderboard)
    ├── client/Main.client.luau       All client UI (HUD, shop, promo banner, completion overlay)
    └── shared/Config.luau            Constants: stage count, prices, IDs, remote names
```

Communication between server and client uses RemoteEvents created by the server
at runtime and awaited by the client via `WaitForChild`.

---

## Setup

### 1. Configure placeholder IDs

In `src/shared/Config.luau`, replace the `0` placeholder values:

```lua
Config.SKIP_STAGE_PRODUCT_ID     = 0  -- Create in Creator Dashboard > Monetization > Developer Products
Config.VIP_GAME_PASS_ID          = 0  -- Create in Creator Dashboard > Monetization > Passes
Config.ALCHEMY_ACADEMY_PLACE_ID  = 0  -- Root place ID of your Alchemy Academy experience
```

### 2. Build the map in Roblox Studio

1. Create a `Folder` named **Checkpoints** in `Workspace`.
2. Add 40 `Part` children. For each:
   - Set attribute `CheckpointNumber` (integer, 1 through 40).
   - Set `Anchored = true`, `CanCollide = false`, `Transparency = 0.5`.
3. Create a `Folder` named **Coins** in `Workspace`.
4. Add `Part` children for each coin pickup:
   - Set attribute `CoinValue` (integer, default 1).
   - Style them however you like (neon material, yellow BrickColor, etc.).
5. Build platforms and jump gaps between checkpoints.

### 3. Sync with Rojo

```sh
cd roblox/obby/
rojo serve default.project.json
```

In Studio: Rojo plugin > Connect > Play to test.

### 4. Create monetization products

In the Creator Dashboard for your published experience:

1. **Developer Product** — "Skip Stage", price 50 Robux. Copy the product ID into `Config.luau`.
2. **Game Pass** — "VIP Pass", price 200 Robux. Copy the pass ID into `Config.luau`.

### 5. Publish

1. File > Publish to Roblox As...
2. Set name, genre, age rating (All Ages).
3. Upload icon (512x512) and screenshots.
4. Enable the experience.

---

## Data Persistence

| DataStore | Key | Value |
|-----------|-----|-------|
| `ObbyCheckpoints_v1` | `UserId` | Highest checkpoint reached (int) |
| `ObbyCoins_v1` | `UserId` | Total coins collected (int) |
| `ObbyBestTimes_v1` | `UserId` | Best completion time in seconds (number) |
| `ObbyFastestTimes_v1` (Ordered) | `UserId` | Best time in centiseconds (int, for leaderboard ranking) |

All DataStore operations are wrapped in `pcall` with warning logs on failure.
Data is saved on `PlayerRemoving` and updated incrementally during gameplay.

---

## Revenue Projections

Based on reported solo obby economics:
- Skip-stage is the primary revenue driver (impulse purchase, repeatable)
- VIP pass provides recurring value and increases session time
- Cross-promo to Alchemy Academy drives traffic to the main game at zero cost

Target: breakeven within first week, $500+/month sustained to unlock Phase 2.

---

## Future Expansion

- **World 2-5**: additional stage sets (40 stages each) unlocked by completion or coins
- **Daily challenges**: randomized stage subset with bonus rewards
- **Cosmetic shop**: trails, death effects, checkpoint animations (coin sink)
- **Seasonal events**: holiday-themed stages with limited-time rewards
- **Group integration**: bonus coins for group members
