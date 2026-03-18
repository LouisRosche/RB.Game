# 18-Month Roadmap Tracker

*Last updated: 2026-03-18*

Legend: ✅ Done · 🔄 In progress · ⬜ Not started

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
- ⬜ Reserve domain name (`alchemyacademy.gg` recommended) — see `docs/platform-setup.md`
- ⬜ Create itch.io account — see `docs/platform-setup.md`

### Skill Building
- ⬜ Complete Roblox Core Curriculum (~15 hrs)
- ⬜ Publish the obby to complete the full publish cycle — project ready at `roblox/obby/`
- ✅ Single-Script Architecture template with ProfileService (production session locking)
- ⬜ Create 5 placeholder art assets in MagicaVoxel
- ⬜ Test sound pipeline (BFXR2, Bosca Ceoil Blue)

### Concept Validation
- ✅ Generate 3 game concepts, apply filters, select one → **Alchemy Academy**
- ✅ Build game design document — see `docs/game-design.md`
- ⬜ Post concepts for community feedback — posts ready in `marketing/community-posts/`

---

## Phase 1: Roblox MVP (Weeks 7-20)
*Budget: $0-40/month | Time: 11-14 hrs/week*

### Sprint 1 — Core Loop (Weeks 7-11)
- ✅ Central gameplay loop (plant → grow → harvest → brew → sell)
- ✅ Server-authoritative Single-Script Architecture
- ✅ 4 ingredients, 10 recipes, 3 lab levels, 3 cauldron levels
- ✅ Mutation rarity system (5 tiers, transparent odds)
- ✅ Rate limiting on all RemoteEvents
- ✅ Inventory caps (ingredients 30, potions 20, seeds 12)
- ⬜ Publish as free, unlisted game
- ⬜ Invite 5-10 testers, measure session length and D1 return rate

### Sprint 2 — Systems (Weeks 11-16)
- ✅ Progression curve (lab upgrades, cauldron upgrades)
- ✅ Full UI built programmatically
- ✅ Leaderboard sidebar (top-10 by TotalGoldEarned)
- ✅ Tutorial/onboarding (5-step overlay, server-saved TutorialCompleted flag)
- ✅ Save system — ProfileService with MemoryStoreService session locking, auto-save, GDPR AddUserId
- ✅ Analytics — funnel tracking via Roblox AnalyticsService
- ✅ Internationalisation — all strings in `Strings.luau`, UTF-8 ready
- ✅ Volume sliders, color-blindness audit PASS
- ⬜ Confirm StreamingEnabled is ON in Studio

### Sprint 3 — Polish & Soft Launch (Weeks 16-20)
- ✅ Visual polish (LightingController, ParticleController, Performance Mode toggle)
- ✅ Sound architecture (SoundController with looping music, SFX pool, rarity stings)
- ⬜ Upload audio assets per `roblox/AUDIO_ASSETS.md`, replace placeholder IDs
- ⬜ Create game icon, thumbnails, description — spec in `docs/store-listing.md`
- ⬜ Publish publicly as free game

### Go/No-Go
- ⬜ D1 retention >= 20% with 100+ unique players
- ⬜ Discord server at 50+ engaged members
- ⬜ Social media posting cadence established

---

## Phase 2: Monetization & Growth (Weeks 21-40)
*Budget: $0-50/month | Time: 10-12 hrs/week*

### Monetization Layers
- ✅ Cosmetic shop: 12 items across 3 categories (placeholder product IDs — create in Creator Hub)
- ✅ Game passes: 3 convenience passes (placeholder IDs — create in Creator Hub)
- ⬜ Rewarded Video Ads (requires 100K+ visits)
- ⬜ A/B price testing
- ⬜ Monitor retention post-monetisation

### Growth
- ⬜ Algorithm optimisation (co-play mechanics, friend invites)
- ⬜ Micro-influencer outreach — see `marketing/influencers/outreach-template.md`
- ⬜ Cross-promotion with 2-3 non-competing Roblox devs
- ⬜ Weekly devlog content on TikTok — see `marketing/tiktok/content-calendar.md`
- ⬜ Localisation: Simplified Chinese, Portuguese (if data supports)

### Go/No-Go
- ⬜ Revenue >= $500/month sustained for 8+ weeks
- ⬜ Discord community >= 200 engaged members
- ⬜ D7 retention >= 8%

---

## Phase 3: Portfolio Expansion (Weeks 41-78)
*Budget: $77-197/month | Time: 12-18 hrs/week*

### Track A: Roblox Maintenance (4-6 hrs/week)
- ✅ Seasonal event system (SeasonalContent + SeasonalService)
- ⬜ Content update every 5-6 weeks
- ⬜ Community management and bug fixes

### Track B: Godot Development (8-12 hrs/week)
- ✅ Godot 4 project scaffolded (project.godot + 4 autoload singletons)
- ✅ Scene scripts written (MainMenu, Lab, Journal, Settings)
- ✅ Scene files (.tscn) created with full node hierarchy
- ⬜ Wire @export node references in Godot editor
- ⬜ Replace ColorRect placeholders with real sprites (art pass)
- ⬜ Write Chapter 1-4 story text + progression triggers

### Steam Launch Pipeline
- ⬜ Build game, publish Steam store page ($100 fee) — see `marketing/steam/store-checklist.md`
- ⬜ Wishlist building (target 7K+)
- ⬜ Steam Next Fest demo (15-30 min, polished)
- ⬜ Localisation, launch at $9.99-$14.99
- ⬜ File trademark before public announcement

---

## Tooling & Infrastructure

- ✅ CI/CD: GitHub Actions — Selene lint, StyLua format check, Rojo validation, GDScript validation, repo hygiene
- ✅ Release automation: GitHub Releases with auto-changelog on `v*` tags
- ✅ Toolchain: Aftman (Rojo 7.4.4, Selene 0.27.1, StyLua 0.20.0)
- ✅ Build automation: Makefile (`make lint`, `make format`, `make rojo`, `make clean`)
- ✅ PR template with testing checklist
- ✅ EditorConfig for cross-editor consistency
