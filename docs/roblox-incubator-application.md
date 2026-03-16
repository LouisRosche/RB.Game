# Roblox Incubator Program — Application Preparation

**Game:** Alchemy Academy
**Developer:** Solo indie (RB.Game)
**Date:** March 16, 2026
**Program:** Roblox Incubator (announced March 9, 2026)

---

## Why Alchemy Academy Qualifies

- **Novel mechanic:** Combinatorial ingredient discovery system. Players do not follow fixed recipes — they experiment by combining 10+ base ingredients through a brewing system grounded in real chemistry concepts (solubility, reactions, catalysts). This creates a massive discovery space from a small content set, rewarding curiosity over guides.
- **Underrepresented genre:** Educational tycoon with science theming. Roblox has thousands of tycoons and simulators, but almost none that blend tycoon progression with genuine science-education crossover mechanics. This directly fits the Incubator's call for "Novel Games" in underrepresented genres.
- **Already built:** 27 production-quality Luau files across server, client, and shared modules. Full game loop implemented — ingredient growing, experimental brewing, potion selling, and lab upgrades are all functional. Single-Script Architecture, ProfileService for data persistence, server-authoritative economy.
- **Solo developer with professional codebase quality:** i18n-ready from day one (all strings externalized in ModuleScript lookup tables), StreamingEnabled, part count managed under 75K, and ethical monetization baked into the architecture — not bolted on.
- **18+ demographic alignment:** The science/discovery angle and anti-dark-pattern philosophy appeal strongly to the 18-24 demographic that Roblox reports is growing 50%+ YoY. The game rewards systems thinking, not time-gating.

---

## Application Narrative (Draft)

*Target length: ~300 words. Suitable for pasting into the Incubator application form.*

Alchemy Academy is a tycoon-simulator where players build and manage a magical alchemy lab — but the core loop is built on genuine discovery, not prescriptive crafting. Players grow magical ingredients, combine them in a brewing system inspired by real chemistry principles, and uncover recipes through experimentation rather than following a wiki. Ten base ingredients generate a combinatorial explosion of possible recipes, meaning the game ships deep content from a lean design surface.

This is a systems-over-content game. Instead of shipping hundreds of hand-authored recipes that players memorize in a week, we built a brewing engine where ingredient properties (volatility, affinity, catalytic behavior) interact dynamically. Players form hypotheses, test combinations, record results in their in-game journal, and share discoveries with friends. The result is a tycoon that feels like a science lab — and that is the point.

The game is not a prototype. We have 27 production Luau files in a Single-Script Architecture, using ProfileService for persistent player data, server-authoritative validation for the economy, and fully externalized strings ready for localization. The tutorial-driven onboarding flow is built and targeting 20%+ D1 retention. Seasonal events (two planned for launch window) extend the discovery space without invalidating existing progress.

Our target audience is 13-to-24-year-old players who are science-curious and underserved by current Roblox offerings. We monetize through cosmetics (lab skins, ingredient particle effects, cauldron styles) and convenience game passes (extra garden plots, recipe journal upgrades). There are no loot boxes, no pay-to-win mechanics, no artificial scarcity timers. Odds for any cosmetic system are transparent and published in-game.

With Incubator support, we would focus on three areas: expanding the ingredient system to 25+ bases with community-suggested elements, building multiplayer co-op brewing sessions, and preparing a polished launch targeting sustained $500+/month revenue. Alchemy Academy is built, it is novel, and it is ready to grow.

---

## Demo Preparation Checklist

- [ ] Record 2-minute Studio gameplay video showing the full loop (grow, brew, discover, sell, upgrade)
- [ ] Prepare a retention strategy one-pager covering tutorial flow, daily hooks, and session pacing
- [ ] Document technical architecture summary: Single-Script Architecture, ProfileService/ProfileStore, server-authoritative economy, StreamingEnabled
- [ ] Gather comparable titles on Roblox and document differentiation points (Potion Craft, Wacky Wizards — what Alchemy Academy does differently)
- [ ] Prepare a one-page monetization philosophy document (cosmetics-only, transparent odds, no FOMO)
- [ ] Screenshot or short clip of the codebase structure showing production quality (module organization, i18n tables, server/client separation)

---

## Key Metrics to Highlight

| Metric | Target | Basis |
|---|---|---|
| D1 Retention | 20-42% | Tutorial-driven onboarding already built; discovery loop provides immediate "aha" moment |
| D7 Retention | 8%+ | Recipe journal + seasonal discoveries create return incentive |
| Content Pipeline | 10 base recipes + 2 seasonal events at launch | Systems-over-content design means each new ingredient multiplies possibilities |
| Monetization | Cosmetics + convenience game passes | Zero pay-to-win, transparent odds, no loot boxes |
| Revenue Target | $500+/month sustained | Go/no-go gate for Phase 3 (Godot/Steam expansion) |
| Localization | i18n-ready from day one | All player-facing strings externalized in ModuleScript lookup tables |

---

## Timeline

| Date | Action |
|---|---|
| March 16, 2026 | This preparation document created |
| Week of March 16-22 | Record gameplay demo video, finalize retention one-pager |
| Week of March 23-29 | Submit Incubator application (target: within 1 week of this document) |
| Application deadline | TBD — check [roblox.com](https://www.roblox.com) for 2026 cohort status |
| Ongoing | Monitor for Jumpstart program details as a backup track |

---

## Notes

- The Incubator program targets experienced small teams with strong prototypes. Position as a solo developer with a production-ready codebase, not a hobbyist with an idea.
- Emphasize the novel genre blend: tycoon + crafting + discovery + collecting. This is not a reskin of an existing template.
- The Jumpstart program (also announced March 9) may be a secondary option if the Incubator cohort is full. Track both.
- Review the application form carefully for word limits before pasting the narrative above — trim if needed but preserve the key differentiators: combinatorial discovery, ethical monetization, production-ready code, i18n from day one.
