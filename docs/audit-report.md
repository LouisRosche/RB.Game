# Alchemy Academy — Project Audit Report

**Date:** March 16, 2026
**Project:** RB.Game / Alchemy Academy
**Type:** Roblox Tycoon/Simulator (Potion Brewing) with Phase 3 Godot/Steam Port
**Author:** Independent Audit

---

## Executive Summary

This project demonstrates exceptional planning discipline but zero shipping velocity. Four detailed research reports, 27 Luau source files, 8 GDScript files, marketing templates, and community drafts have been produced — all to production-quality standards — but none of it has been tested by real players.

The core problem is straightforward: the project is optimizing for perfection in a market that rewards speed. The 2026 landscape has shifted decisively. The winning sequence is now:

**Market -> Validate -> Build -> Launch -> Scale**

Not: Research -> Plan -> Build -> Polish -> Launch.

Every week spent planning without shipping is a week of player data that does not exist. The recommendations in this report are ordered by urgency, not importance.

---

## What's Strong

The foundation here is genuinely above-average for a solo indie project. Specifically:

- **4 research reports with data-backed decisions.** Market sizing, competitor analysis, monetization benchmarks, and platform economics are all documented with sources. Most solo developers skip this entirely.
- **27 Luau source files following Single-Script Architecture best practices.** The codebase uses one ServerScript and one LocalScript requiring ModuleScripts, exactly as recommended by Roblox engineering guidelines.
- **Server-authoritative design with ProfileService integration.** Economy, inventory, and progression logic runs server-side. Client never trusted with state mutations. This prevents the most common exploit vectors on Roblox.
- **i18n-ready string externalization from day one.** All player-facing strings live in ModuleScript lookup tables. Localization will not require a codebase rewrite.
- **Anti-dark-pattern monetization strategy.** Cosmetics-only model, transparent odds, no loot boxes, no pay-to-win mechanics. This aligns with both Roblox policy direction and emerging regulatory trends.
- **Phase-gated execution with explicit kill criteria.** D1 retention >= 20% as go/no-go for Phase 2, $500/month sustained revenue as go/no-go for Phase 3. These are concrete, measurable thresholds — not vibes.
- **Godot architecture well-structured with 8 GDScript files and autoload singletons.** The standalone port has a clean separation of concerns and follows Godot 4 conventions.
- **Comprehensive marketing templates.** TikTok content calendar, influencer outreach scripts, Discord community posts, and DevForum feedback drafts are written and ready to deploy.

---

## Critical Gaps

These are not nice-to-haves. Each one is a blocker or a high-severity risk.

### 1. ProfileService.luau is a STUB

The file exists but does not contain the actual ProfileService library. It must be replaced with the real library (or migrated to ProfileStore) before any player touches the game. Without it, player data will not persist between sessions. Session-locking — the mechanism that prevents inventory duplication — is completely absent.

**Action:** Download the real ProfileService module from the official repository. Test session-locking behavior with multiple clients in Studio.

### 2. All 13 audio asset IDs are placeholders

Every sound reference in the codebase points to placeholder IDs. The game will be completely silent on launch. Silent games have measurably lower retention — audio feedback is a core engagement loop in tycoon/simulators.

**Action:** Source or create audio assets for at minimum: potion brewing, ingredient collection, purchase confirmation, level-up, and ambient background. Upload to Roblox and replace placeholder IDs.

### 3. Testing infrastructure is incomplete

A test runner and three test suites now exist (`roblox/tests/TestRunner.server.luau`, `RecipeTests.luau`, `EconomyTests.luau`, `SeasonalTests.luau`), covering shared module logic for recipes, economy, and seasonal content. This is a meaningful start. However, there are no integration tests, no CI pipeline, and no automated quality gates. Coverage is limited to shared modules — server and client code paths are untested. A single broken ModuleScript can still silently break the entire game due to the Single-Script Architecture.

**Action:** Expand test coverage to server and client modules. Add integration tests for critical paths (data loading, economy transactions, inventory operations). Set up a basic CI pipeline that runs tests on every commit.

### 4. No game has been published

Zero real player data exists. All retention estimates, monetization projections, and engagement assumptions are theoretical. The project's own kill criteria (D1 >= 20%) cannot be evaluated because there is no D1 data.

**Action:** Publish an unlisted Roblox experience and recruit 10-20 testers. Instrument analytics from the first session.

### 5. Business formation not started

LLC, domain registration, and trademark filing have not been initiated. "Alchemy Academy" is a descriptive name in a popular genre — the risk of name squatting increases with every day of delay.

**Action:** Register the domain this week. File LLC paperwork. Begin trademark search.

### 6. Godot scene files (.tscn) do not exist

The 8 GDScript files reference scenes that have not been built. Scripts are written for a game that cannot run. This is not blocking for Phase 1 (Roblox), but it means Phase 3 readiness is lower than the file count suggests.

**Action:** Defer until Phase 3 timeline approaches, but do not count Godot files as "progress" in current status updates.

---

## Market Intelligence (March 2026)

### Roblox Platform

- **380M monthly active users, 151.5M daily active users.** The platform continues to grow, with the 18-34 demographic growing 50%+ year-over-year.
- **D1 retention benchmark: 42% is achievable** with a well-designed tutorial flow and first-session hook. The project's target of 20% is conservative — this is good as a kill criterion but should not be the aspiration.
- **DevEx payouts:** Creators earned over $1 billion in the 12 months ending March 2025. The economic opportunity is real and growing.

### New Opportunities

- **Roblox Incubator program launched March 9, 2026.** Roblox is actively seeking applications from small teams building novel game concepts. An alchemy/potion-brewing tycoon with server-authoritative architecture and anti-dark-pattern monetization is exactly the profile they are looking for. Applications are open now.
- **Rewarded Video Ads** are a new monetization channel with 87% player approval ratings. They monetize non-spending players without degrading the experience. This is a natural fit for a cosmetics-only economy — players watch an ad, receive a cosmetic or currency bonus.
- **Solo obby developers report $20,000-$27,000/month** in revenue. The existing `obby/` subfolder in this project is underinvested relative to this opportunity.

### Monetization Benchmarks

- **Top-performing game passes:** VIP access (100-500 Robux), 2x Multiplier (50-300 Robux). The project already has both of these designed.
- **Cosmetic items:** The highest-margin, lowest-controversy monetization path. Aligns with the project's stated principles.

---

## Strategic Recommendations

Ordered by urgency. Items 1-3 should begin this week.

### 1. SHIP THE OBBY IMMEDIATELY

The `obby/` subfolder represents the lowest-risk, fastest feedback loop available. Obby games have a proven revenue model, minimal content requirements, and established player expectations. Shipping it accomplishes three things simultaneously: it generates real player data, it produces revenue (even small amounts validate the pipeline), and it breaks the psychological barrier of "I haven't shipped anything yet."

**Timeline:** This week.

### 2. Soft-launch Alchemy Academy as an unlisted Roblox game within 2 weeks

Replace the ProfileService stub, add placeholder audio (even stock sounds), and publish as unlisted. Recruit 10-20 testers from Discord or DevForum. Instrument basic analytics: session length, tutorial completion rate, D1 return rate. This data is worth more than any additional planning.

**Timeline:** 2 weeks from today (March 30, 2026).

### 3. Apply to the Roblox Incubator program

Applications are open now. The project's documentation, code quality, and anti-dark-pattern stance are strong differentiators. Even if the application is not accepted, the process of writing it will force clarity on the game's unique value proposition.

**Timeline:** Before the application window closes.

### 4. Add Rewarded Video Ads as a revenue stream

Integrate Rewarded Video Ads for non-paying players. This monetizes the long tail of players who will never purchase Robux items, and it does so with high player approval. Implementation is straightforward through the Roblox ads API.

**Timeline:** Phase 2, but plan the integration points now.

### 5. Expand test coverage and add CI before the codebase grows further

Unit tests exist for shared modules (recipes, economy, seasonal content), but there are no integration tests and no CI pipeline. The Single-Script Architecture means a single broken module can cascade — automated tests on every commit are the safety net. Priorities: integration tests for critical paths (data loading, economy transactions, inventory operations), then a CI pipeline that runs all tests before merges.

**Timeline:** Before soft launch.

### 6. Register LLC and domain before the name gets taken

"Alchemy Academy" is descriptive enough that someone else could register it independently. Domain registration is cheap and fast. LLC formation protects personal assets once revenue starts flowing.

**Timeline:** This week.

### 7. Post community feedback drafts

DevForum posts, Reddit threads, and Discord community announcements are already written. Post them. Community feedback before launch is free QA and free marketing. Every day they sit in a drafts folder is wasted value.

**Timeline:** This week.

### 8. Shift mindset from "plan more" to "ship and iterate"

This is the meta-recommendation. The project's greatest strength — thorough planning — has become its primary bottleneck. The next unit of value comes from player data, not from another planning document. Ship, measure, learn, iterate.

---

## Risk Assessment

| Risk | Severity | Mitigation |
|------|----------|------------|
| Analysis paralysis — continued planning without shipping | **HIGH** | Time-box Phase 0 to end this month. Force a soft launch by March 30, 2026. |
| ProfileService stub deployed to production | **CRITICAL** | Download the real library immediately. Test session-locking with multiple Studio clients before any player access. |
| No real player data to validate assumptions | **HIGH** | Unlisted soft launch with 10-20 recruited testers. Instrument analytics from session one. |
| Name squatting on domain or trademark | **MEDIUM** | Register domain this week. Begin trademark search process. |
| Burnout from over-planning without visible progress | **MEDIUM** | Ship something small (the obby) to generate momentum and motivation. Small wins compound. |
| Silent game due to placeholder audio IDs | **MEDIUM** | Source basic sound effects before soft launch. Stock audio is acceptable for testing. |
| Godot port appears further along than it is | **LOW** | Acknowledge that .tscn files do not exist. Do not count GDScript files toward Phase 3 readiness metrics. |

---

## Sources

- GameAnalytics 2025 Roblox Benchmark Report
- Roblox Economic Impact Report (September 2025)
- Roblox Incubator & Jumpstart announcement (March 9, 2026)
- Game Developer: "Biggest Roblox creators earned average $1.3M in 2025"
- How To Market A Game: Steam release data 2025

---

*This audit report is intended as an actionable assessment, not a critique. The project's foundation is strong. The priority now is to convert planning into shipping.*
