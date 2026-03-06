# 18-Month Roadmap Tracker

*Last updated: 2026-03-06*

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
- ⬜ Create Roblox developer account with 2FA
- ⬜ Search 3 candidate game names on USPTO TESS
- ⬜ Reserve domain name for top candidate
- ⬜ Create itch.io account

### Skill Building
- ⬜ Complete Roblox Core Curriculum (~15 hrs)
- ⬜ Publish a trivial game (obby) to complete the full publish cycle
- ✅ Set up Single-Script Architecture template with ProfileService
- ⬜ Create 5 placeholder art assets in MagicaVoxel
- ⬜ Test sound pipeline (BFXR2, Bosca Ceoil Blue)

### Concept Validation
- ✅ Generate 3 game concepts (tycoon/simulator or idle genre)
- ✅ Apply filters: content treadmill, monetization fit, social play, art ceiling, scope
- ✅ Build paper prototype or game design document for top concept
- ⬜ Post concepts for community feedback (r/RobloxGameDev, DevForum, Discord)
- ✅ Select one concept for Phase 1 → **Alchemy Academy** (educational idle)

---

## Phase 1: Roblox MVP (Weeks 7-20)
*Budget: $0-40/month | Time: 11-14 hrs/week*

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
- ✅ Save system — ProfileService migration (session locking, auto-save, GDPR AddUserId)
  - **⚠ Action required**: download `ProfileService.luau` → `roblox/src/server/Vendor/` (see INSTALL.md)
- ✅ Analytics — funnel tracking (plant/harvest/brew) for D1/D7 measurement via Roblox AnalyticsService
- ✅ Internationalisation — all strings in `Strings.luau`, UTF-8 ready
- 🔄 Accessibility Big Four (remappable controls, subtitles, volume sliders, no color-only info)
  - ✅ Volume sliders — Settings panel in HUD (Music +/−, SFX +/−, Mute All)
  - ⬜ Remappable controls (low priority for Roblox — platform handles most)
  - ⬜ Subtitles for any future voiced content
  - ⬜ Color-blindness audit (rarity colours have sufficient contrast by design)
- ⬜ Performance optimisation audit (< 75K parts, StreamingEnabled confirmed on)

### Sprint 3 — Polish & Soft Launch (Weeks 16-20)
- ⬜ Visual polish (lighting, particles, post-processing)
- ✅ Sound architecture — SoundController with looping music, SFX pool, per-rarity harvest stings
  - **⚠ Action required**: upload audio assets, replace placeholder IDs in `SoundController.luau`
- ⬜ Distinct SFX per action recorded/purchased (plant, harvest ×5 rarities, brew, sell, upgrade, discovery)
- ⬜ Background music track chosen and uploaded
- ⬜ Game icon, thumbnails, description optimised
- ⬜ Publish publicly as free game (no monetization yet)

### Go/No-Go
- ⬜ D1 retention >= 20% with 100+ unique players
- ⬜ Discord server at 50+ engaged members — see `community/discord/setup.md`
- ⬜ Social media posting cadence established — see `marketing/tiktok/content-calendar.md`

---

## Phase 2: Monetization & Growth (Weeks 21-40)
*Budget: $0-50/month + optional influencer budget | Time: 10-12 hrs/week*

### Monetization Layers
- ⬜ Cosmetic shop: 10-15 items, prices A/B tested
- ⬜ Game passes: 2-3 convenience passes (2× speed, auto-harvest, VIP theme)
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
- ⬜ Content update every 5-6 weeks
- ⬜ Community management and bug fixes
- ⬜ Maintain revenue stream

### Track B: Godot Development (8-12 hrs/week)
- ⬜ Complete Godot "Your First 2D Game" tutorial
- ⬜ Build standalone game (same universe, not a direct port)

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

1. **Install ProfileService** — download from https://github.com/MadStudioRoblox/ProfileService/releases, place at `roblox/src/server/Vendor/ProfileService.luau`
2. **Upload audio** — any free sound pack will do to unblock testing; replace placeholder IDs in `SoundController.luau`
3. **Publish unlisted on Roblox** — invite 5-10 testers, measure D1 retention (tutorial is now built ✅)
4. **Set up business basics** — LLC, bank account, tax savings account (Phase 0 blockers for monetisation)
5. **Start Discord server** — follow `community/discord/setup.md`; have it live before any public TikTok posts
6. **Start TikTok** — first video before the public launch, not after
