# CLAUDE.md

## Project Overview

RB.Game is a solo indie game development project following an 18-month, 4-phase plan:
- Phase 0: Foundation (business, tools, concept validation)
- Phase 1: Roblox MVP (tycoon/simulator, target D1 retention >= 20%)
- Phase 2: Monetization & Growth (cosmetics, game passes, $500+/month)
- Phase 3: Godot standalone game for Steam (7K+ wishlists, localized launch)

## Repo Layout

- `research/` — Three strategy reports (read these first for full context)
- `roblox/src/` — Luau source: `server/`, `client/`, `shared/` (Single-Script Architecture with ModuleScripts)
- `roblox/assets/` — Roblox game art, sound, UI
- `godot/` — Godot 4 standalone game: `src/`, `assets/`, `scenes/`
- `marketing/` — TikTok content, Steam store assets, influencer outreach
- `community/discord/` — Discord server setup and resources
- `business/` — Legal (trademarks, LLC) and finance (budget, taxes)
- `docs/` — Roadmap tracker and guides

## Tech Conventions

- Roblox: Single-Script Architecture — one ServerScript + one LocalScript requiring ModuleScripts
- Data persistence: ProfileService/ProfileStore (never raw DataStoreService)
- Strings: externalized in ModuleScript lookup tables (i18n-ready from day one)
- Performance: part count < 75K, StreamingEnabled on, anchor static parts
- Monetization: cosmetics and convenience only — no loot boxes, no pay-to-win
- Godot: GDScript, 2D-first, MIT license (zero royalties)

## Key Metrics

- D1 Retention target: >= 20% (go/no-go for Phase 2)
- D7 Retention target: >= 8%
- Revenue target: >= $500/month sustained (go/no-go for Phase 3)
- Steam wishlists: >= 7,000 before launch
- Discord community: >= 200 engaged members
