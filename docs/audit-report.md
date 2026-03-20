# Alchemy Academy — Project Audit Report

**Date:** March 20, 2026 (Living document — updated as gaps are resolved)
**Project:** RB.Game / Alchemy Academy

---

## Executive Summary

This project demonstrates exceptional planning discipline but zero shipping velocity. Four detailed research reports, 27 Luau source files, 8 GDScript files, marketing templates, and community drafts have been produced — all to production-quality standards — but none of it has been tested by real players.

The core problem is straightforward: the project is optimizing for perfection in a market that rewards speed. The winning sequence is:

**Market -> Validate -> Build -> Launch -> Scale**

---

## What's Strong

- **4 research reports with data-backed decisions.** Market sizing, competitor analysis, monetization benchmarks, and platform economics are all documented with sources.
- **27 Luau source files following Single-Script Architecture best practices.**
- **Server-authoritative design with ProfileService integration.** Economy, inventory, and progression logic runs server-side.
- **i18n-ready string externalization from day one.**
- **Anti-dark-pattern monetization strategy.** Cosmetics-only model, transparent odds, no loot boxes, no pay-to-win.
- **Phase-gated execution with explicit kill criteria.** D1 >= 20%, $500/month sustained revenue.
- **Godot architecture well-structured with 8 GDScript files and autoload singletons.**
- **Comprehensive marketing templates.** TikTok content calendar, influencer outreach, Discord community posts, DevForum drafts.

---

## Gaps Identified and Remediation Status

| Gap | Severity | Status |
|-----|----------|--------|
| ProfileService.luau was a stub (no session locking) | CRITICAL | **RESOLVED** — replaced with production module using MemoryStoreService session locking |
| All 13 audio asset IDs are placeholders | HIGH | OPEN — source/create audio, upload to Roblox, replace IDs in SoundController.luau |
| No CI/CD pipeline | HIGH | **RESOLVED** — GitHub Actions CI (lint, format, Rojo validation, hygiene checks) |
| No linting or formatting tools | HIGH | **RESOLVED** — Selene + StyLua configured with Aftman toolchain |
| Godot .tscn scene files did not exist | MEDIUM | **RESOLVED** — 4 scenes created (MainMenu, Lab, Journal, Settings) |
| No game published | HIGH | OPEN — publish unlisted, recruit 10-20 testers |
| Business formation not started | MEDIUM | OPEN — LLC, domain, EIN |
| No Privacy Policy or Terms of Service | HIGH | **RESOLVED** — created at business/legal/privacy-policy.md and business/legal/terms-of-service.md |
| Game design doc values don't match Config.luau | MEDIUM | **RESOLVED** — GDD updated to match Config.luau source of truth |
| Missing CCPA/CARU/FTC compliance documentation | MEDIUM | **RESOLVED** — added to business/legal/checklist.md |
| Discord setup missing age verification requirement | MEDIUM | **RESOLVED** — COPPA-compliant age notice added to community/discord/setup.md |
| Privacy Policy Section 4.5 cross-reference error | MEDIUM | **RESOLVED** — fixed "Section 9" → "Section 10" |
| REFUND_NOTICE claims USD values displayed (they aren't) | MEDIUM | **RESOLVED** — removed inaccurate claim |
| Missing ArePaidRandomItemsRestricted PolicyService check | LOW | **RESOLVED** — precautionary check added to UIController |
| VIP pass lists undeliverable "future cosmetics" benefit | LOW | **RESOLVED** — replaced with honest benefit text |
| No DPIA document for UK AADC compliance | LOW | OPEN — create before Phase 3 |
| No data breach response plan document | LOW | OPEN — create before Phase 2 |

---

## Market Intelligence (March 2026)

- **380M monthly active users, 151.5M daily active users.** 18-34 demographic growing 50%+ YoY.
- **D1 retention benchmark: 42% is achievable** with a solid tutorial. Target of 20% is conservative.
- **DevEx payouts:** Creators earned over $1 billion in the 12 months ending March 2025.
- **Roblox Incubator program launched March 9, 2026.** Applications open.
- **Rewarded Video Ads** have 87% player approval. Requires 100K+ visits.
- **Solo obby developers report $20,000-$27,000/month** in revenue.

---

## Risk Assessment

| Risk | Severity | Mitigation |
|------|----------|------------|
| Analysis paralysis | HIGH | Time-box Phase 0. Force soft launch. |
| No real player data | HIGH | Unlisted soft launch with 10-20 testers. |
| Name squatting | MEDIUM | Register domain before first public post. |
| Burnout from over-planning | MEDIUM | Ship the obby to generate momentum. |
| Silent game (placeholder audio) | MEDIUM | Source basic SFX before soft launch. |

---

## Sources

- GameAnalytics 2025 Roblox Benchmark Report
- Roblox Economic Impact Report (September 2025)
- Roblox Incubator & Jumpstart announcement (March 9, 2026)
- Game Developer: "Biggest Roblox creators earned average $1.3M in 2025"
- How To Market A Game: Steam release data 2025
