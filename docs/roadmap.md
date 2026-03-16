# 18-Month Roadmap Tracker

*Last updated: 2026-03-16*

Legend: ✅ Done · 🔄 In progress · 📝 Ready (docs/code prepared — execute manually) · ⬜ Not started

> **Market Context (March 2026 Audit)**
>
> - Roblox has reached **380M MAU**; the 18-34 demographic is growing **50%+ YoY**, making it viable for broader audiences
> - 2026 paradigm: **Market → Validate → Build → Launch → Scale** — validate demand before heavy development
> - D1 retention of **42% is achievable** with a solid tutorial (industry baseline 20% is the floor, not the ceiling)
> - Solo obby developers have proven **$20-27K/month** revenue — simple games with strong retention outperform complex ones
> - Rewarded Video Ads have **87% player approval** on Roblox; they monetize non-paying players with zero friction

---

## Phase 0: Foundation (Weeks 1-6)
*Budget: $0-62 | Time: 10-15 hrs/week*

### Business & Legal
- ⬜ Register business entity (sole prop or LLC) — see `business/legal/checklist.md`
- ⬜ Open dedicated business bank account
- ⬜ Open tax savings account (auto-transfer 33% of income)
- ⬜ Set up financial tracking (Wave or GnuCash) — see `business/finance/budget.md`

### Platform Setup
- ⬜ Create Roblox developer account with 2FA — see `docs/platform-setup.md`
- 📝 Search 3 candidate game names on USPTO TESS — research documented in `docs/trademark-domain-research.md`
- ⬜ Reserve domain name for top candidate (`alchemyacademy.gg` recommended) — see `docs/platform-setup.md`
- ⬜ Create itch.io account — see `docs/platform-setup.md`

### Skill Building
- ⬜ Complete Roblox Core Curriculum (~15 hrs)
- 📝 Publish a trivial game (obby) to complete the full publish cycle — project ready at `roblox/obby/`, follow `roblox/obby/README.md`
- 🔄 Set up Single-Script Architecture template with ProfileService — **CRITICAL: ProfileService stub is non-functional; must be replaced with real ProfileService or ProfileStore (the 2026 successor, recommended for new projects) before any playtesting**
- ⬜ Create 5 placeholder art assets in MagicaVoxel
- ⬜ Test sound pipeline (BFXR2, Bosca Ceoil Blue)

### Concept Validation
- ✅ Generate 3 game concepts (tycoon/simulator or idle genre)
- ✅ Apply filters: content treadmill, monetization fit, social play, art ceiling, scope
- ✅ Build paper prototype or game design document for top concept
- 📝 Post concepts for community feedback — posts drafted in `marketing/community-posts/` (DevForum + r/RobloxGameDev + r/roblox)
- ✅ Select one concept for Phase 1 → **Alchemy Academy** (educational idle)

---

## Phase 0.5: Quick Wins (1-2 Weeks)
*Budget: $0 | Time: focused sprint before Phase 1 soft launch*

The March 2026 audit identified several items that can ship immediately with minimal effort. These build momentum, exercise the publish pipeline, and unlock time-sensitive opportunities.

### Ship Now
- ⬜ **Ship the obby game** — project is ready at `roblox/obby/`; 1-2 days of work to publish and complete the full Roblox publish cycle
- ⬜ **Soft-launch Alchemy Academy as Unlisted** — requires ProfileService/ProfileStore replacement **(CRITICAL)** + audio upload first (see Audit Actions below), then publish as unlisted for initial playtesting
- ⬜ **Post community feedback drafts** — posts are already written in `marketing/community-posts/`; copy to DevForum and r/RobloxGameDev
- ⬜ **Apply to Roblox Incubator program** — time-sensitive opportunity, March 2026 window; submit application before deadline

### Why This Phase Exists
Phase 0 business items (LLC, bank account, domain) are incomplete but **should not block** the soft launch. A game running unlisted with 10-20 testers generates real retention data, which informs every decision downstream. Ship first, incorporate later.

---

## Phase 1: Roblox MVP (Weeks 7-20)
*Budget: $0-40/month | Time: 11-14 hrs/week*

> **March 2026 Update:** Most Sprint 1 and Sprint 2 code is complete. Phase 0 business items (LLC, bank account, domain) remain incomplete but **do not block soft launch**. The critical path is: **replace ProfileService stub with real ProfileService or ProfileStore (recommended for new projects)** → upload audio → create store listing assets → publish unlisted → invite testers. Target: soft launch by end of March 2026.

### Sprint 1 — Core Loop (Weeks 7-11)
- ✅ Build central gameplay loop (plant → grow → harvest → brew → sell)
- ✅ Server-authoritative Single-Script Architecture
- ✅ 4 ingredients, 10 recipes, 3 lab levels, 3 cauldron levels
- ✅ Mutation rarity system (5 tiers, transparent odds)
- ✅ Rate limiting on all RemoteEvents (economy exploit prevention)
- ✅ Inventory caps (ingredients 30, potions 20, seeds 12)
- ⬜ Publish as free, unlisted game
- ⬜ Invite 5-10 testers, measure session length and D1 return rate

### Sprint 2 — Systems (Weeks 11-16)
- ✅ Progression curve (lab upgrades, cauldron upgrades)
- ✅ Full UI built programmatically — HUD, seed/brew/sell/upgrade/journal panels
- ✅ Leaderboard sidebar (top-10 by TotalGoldEarned, live broadcasts)
- ✅ Tutorial/onboarding — `TutorialController.luau`: 5-step overlay, state-diff advancement, skip button, server-saved TutorialCompleted flag
- 🔄 Save system — ProfileService migration (session locking, auto-save, GDPR AddUserId) — **CRITICAL: stub only, no real data persistence; player data WILL BE LOST without replacement**
  - ✅ ProfileService stub installed at `roblox/src/server/Vendor/ProfileService.luau` — game runs in Studio but **does not persist data**
  - **🚨 CRITICAL — Replace before ANY playtesting**: download real ProfileService from GitHub (see INSTALL.md), or migrate to **ProfileStore** (the 2026 successor by the same author, recommended for all new projects)
- ✅ Analytics — funnel tracking (plant/harvest/brew) for D1/D7 measurement via Roblox AnalyticsService
- ✅ Internationalisation — all strings in `Strings.luau`, UTF-8 ready
- 🔄 Accessibility Big Four (remappable controls, subtitles, volume sliders, no color-only info)
  - ✅ Volume sliders — Settings panel in HUD (Music +/−, SFX +/−, Mute All)
  - ⬜ Remappable controls (low priority for Roblox — platform handles most)
  - ⬜ Subtitles for any future voiced content
  - ✅ Color-blindness audit — PASS: all rarity info conveyed by text name; color is supplementary only
- ✅ Performance audit — ~17 parts/player max; 50 players = 850 parts (well under 75K); all static parts anchored
  - **⚠ Confirm StreamingEnabled is ON in Studio** → Workspace Properties → Streaming Enabled

### Sprint 3 — Polish & Soft Launch (Weeks 16-20)
- ✅ Visual polish (lighting, particles, post-processing)
  - ✅ `LightingController.luau`: bloom, atmosphere, colour correction
  - ✅ `ParticleController.luau`: cauldron idle bubbles, rarity-burst harvest sparkles, brew-complete burst, discovery fanfare
  - ✅ Performance Mode toggle in Settings panel (disables all visual effects for low-end devices)
- ✅ Sound architecture — SoundController with looping music, SFX pool, per-rarity harvest stings
  - **⚠ Action required**: upload audio assets per `roblox/AUDIO_ASSETS.md`, replace placeholder IDs in `SoundController.luau`
- ⬜ Distinct SFX per action recorded/purchased — sourcing guide at `roblox/AUDIO_ASSETS.md`
- ⬜ Background music track chosen and uploaded — see `roblox/AUDIO_ASSETS.md`
- 📝 Game icon, thumbnails, description — spec written in `docs/store-listing.md`; assets need to be created and uploaded
- ⬜ Publish publicly as free game (no monetization yet)

### Go/No-Go
- ⬜ D1 retention >= 20% with 100+ unique players
- ⬜ Discord server at 50+ engaged members — see `community/discord/setup.md`
- ⬜ Social media posting cadence established — see `marketing/tiktok/content-calendar.md`

---

## Phase 2: Monetization & Growth (Weeks 21-40)
*Budget: $0-50/month + optional influencer budget | Time: 10-12 hrs/week*

### Monetization Layers
- ✅ Cosmetic shop: 12 items across 3 categories (Lab Themes, Cauldron Tints, Harvest Particles)
  - ✅ `shared/Cosmetics.luau` — all item definitions with placeholder product IDs
  - ✅ `server/Services/MonetizationService.luau` — ProcessReceipt handler, equip validation
  - ✅ Cosmetic Shop panel in UIController (tabbed, scrollable, Equip/Buy buttons)
  - **⚠ Action required**: create Developer Products in Creator Hub, replace placeholder IDs in `Cosmetics.luau`
- ✅ Game passes: 3 convenience passes (Speed Brew 199R, Auto-Harvest 299R, VIP 99R)
  - ✅ `shared/GamePasses.luau` — pass definitions with placeholder IDs
  - ✅ GrowthService applies Speed Brew (2× faster growth) and Auto-Harvest (plots self-collect)
  - ✅ MonetizationService checks passes on join, re-verifies after purchase prompt
  - **⚠ Action required**: create Game Passes in Creator Hub, replace placeholder IDs in `GamePasses.luau`
- ⬜ **Rewarded Video Ads** — 87% player approval rate; monetizes non-paying players without friction
  - Requires **100K+ visits** to enable (Roblox policy threshold)
  - Reward options: 2× growth speed for 10 min, bonus gold, free seed pack
  - No-ad game pass as premium alternative for paying players
  - Implementation: integrate Roblox `PolicyService` ad API once visit threshold is met
- ⬜ A/B price testing — run first for 2 weeks post-launch before changing prices
- ⬜ Monitor retention post-monetisation (no significant drop acceptable)
- ⬜ Optional: seasonal event with dual-track battle pass

### Growth
- ⬜ Algorithm optimisation (co-play mechanics, friend invites)
- ⬜ Micro-influencer outreach (5-10 creators, 5K-50K subs) — see `marketing/influencers/outreach-template.md`
- ⬜ Cross-promotion with 2-3 non-competing Roblox devs
- ⬜ Weekly devlog content on TikTok — see `marketing/tiktok/content-calendar.md`
- ⬜ Localisation: Simplified Chinese, Portuguese (if data supports)

### Go/No-Go
- ⬜ Revenue >= $500/month sustained for 8+ weeks
- ⬜ Discord community >= 200 engaged members — see `community/discord/setup.md`
- ⬜ D7 retention >= 8%

---

## Phase 3: Portfolio Expansion (Weeks 41-78)
*Budget: $77-197/month | Time: 12-18 hrs/week*

### Track A: Roblox Maintenance (4-6 hrs/week)
- ✅ Seasonal event system — `SeasonalContent.luau` + `SeasonalService.luau`
  - Winter Festival (Dec 25 – Jan 8): Frost Blossom, Aurora Moss, 3 seasonal recipes
  - Spring Bloom (Mar 21 – Apr 5): Pollinator Petal, Mycelium Bloom, 3 seasonal recipes
  - SeasonalService rechecks calendar every 10 min; broadcasts `SeasonalUpdate` to clients
  - **⚠ Action required**: add seasonal seed rows to shop UI; expand BrewingService to check seasonal recipes via `SeasonalService.lookupActiveRecipe`
- ⬜ Content update every 5-6 weeks
- ⬜ Community management and bug fixes
- ⬜ Maintain revenue stream

### Track B: Godot Development (8-12 hrs/week)
- ✅ Godot 4 project scaffolded — `godot/project.godot` + 4 autoload singletons
  - `GameState.gd` — inventory, gold, chapter, discovery tracking, signals
  - `SaveManager.gd` — ConfigFile save/load; settings isolated from progress
  - `Ingredients.gd` — 10 ingredients (4 cross-universe with Roblox + 6 new)
  - `Recipes.gd` — 15 recipes, order-independent lookup, rarity value formula
- ✅ Scene scripts written: `MainMenu.gd`, `Lab.gd`, `Journal.gd`, `Settings.gd`
  - `scenes/SCENE_STRUCTURE.md` — full node tree guide for building .tscn files
  - `godot/README.md` — complete dev setup, architecture, and Steam export guide
- ⬜ Create .tscn scene files in Godot editor — follow `scenes/SCENE_STRUCTURE.md`
- ⬜ Replace ColorRect placeholders with real sprites (art pass)
- ⬜ Write Chapter 1–4 story text + progression triggers

### Steam Launch Pipeline
- ⬜ Weeks 41-55: Build game, publish Steam store page ($100 fee) — see `marketing/steam/store-checklist.md`
- ⬜ Weeks 55-65: Wishlist building (target 7K+)
- ⬜ Weeks 65-70: Steam Next Fest demo (15-30 min, polished)
- ⬜ Weeks 70-78: Localisation, launch at $9.99-$14.99
- ⬜ File trademark before public announcement — see `business/legal/checklist.md`
- ⬜ Consider Epic Games Store dual-listing

### Portfolio Assessment (Month 18)
- ⬜ Evaluate combined performance of both games
- ⬜ Decision: scale up, double down on winner, or begin Game 3

---

## Immediate Next Actions

These are the blockers before the game can be playtested:

1. **Create Roblox developer account** — follow `docs/platform-setup.md`; start the 30-day DevEx clock now
2. **Register domain** — `alchemyacademy.gg` or `.game` before any public post; ~$20–35/yr at porkbun.com
3. **🚨 Install ProfileService or ProfileStore (CRITICAL)** — download ProfileService from https://github.com/MadStudioRoblox/ProfileService/releases, or use **ProfileStore** (the 2026 successor, recommended for new projects) from https://github.com/MadStudioRoblox/ProfileStore; place at `roblox/src/server/Vendor/ProfileService.luau`
4. **Upload audio** — follow `roblox/AUDIO_ASSETS.md` for exact files needed; replace placeholder IDs in `SoundController.luau`
5. **Publish the practice obby** — follow `roblox/obby/README.md` to exercise the full publish workflow before the real launch
6. **Post concept feedback** — copy posts from `marketing/community-posts/` to DevForum and Reddit
7. **Set up business basics** — LLC, bank account, tax savings account (see `business/legal/checklist.md`)
8. **Start Discord server** — follow `community/discord/setup.md`; live before any public TikTok posts
9. **Start TikTok** — first video before the public launch, not after (see `marketing/tiktok/content-calendar.md`)

---

## Audit Actions (March 2026)

Identified during the March 2026 codebase and market audit. Items marked **(blocker)** must be resolved before soft launch.

- [ ] **🚨 CRITICAL:** Download real ProfileService from GitHub and replace stub **(blocker)** — see `roblox/INSTALL.md`. **Note:** ProfileStore (by the same author, luevent/MadStudioRoblox) is the 2026 successor to ProfileService and is now the recommended choice for new projects. Consider migrating directly to ProfileStore instead of installing legacy ProfileService.
- [ ] Upload audio assets and replace placeholder IDs in `SoundController.luau` **(blocker)** — see `roblox/AUDIO_ASSETS.md`
- [ ] Create game icon and thumbnails **(blocker)** — spec in `docs/store-listing.md`
- [ ] Add testing infrastructure — unit tests for core systems (economy, brewing, progression)
- [ ] Ship obby game — exercise full publish pipeline; `roblox/obby/README.md`
- [ ] Apply to Roblox Incubator — March 2026 window, time-sensitive
- [ ] Register domain — `alchemyacademy.gg` or `.game`; ~$20-35/yr at porkbun.com
- [ ] Form LLC — see `business/legal/checklist.md`
- [ ] Soft launch with 10-20 testers — publish as unlisted, invite testers, measure D1 retention
