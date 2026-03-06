# RB.Game — Alchemy Academy

A free educational game where players discover the real science of alchemy — built on Roblox for instant, zero-install access at massive scale.

**Core belief:** Games should make people smarter, happier, and more curious. Zero dark patterns, ever.

---

## What Is Alchemy Academy?

An idle discovery game for ages 8-16 (and curious adults) on Roblox. Players grow magical ingredients, brew potions, and unlock the real science hiding behind every recipe — bioluminescence, geothermal energy, nuclear fusion, convection, and more.

**Free to play. Free to learn. No pay-to-win. No FOMO. No tricks.**

### Why It Works

- **Viral through joy**: Recipe discoveries are celebrated server-wide. Science facts spread naturally.
- **Scalable from day one**: Roblox handles all infrastructure — no servers, no deployment, no ops.
- **Genuinely educational**: Each of 10 recipes unlocks a real science concept in the Alchemist's Journal.
- **Ethical by design**: Full probability transparency, no punishing timers, no manipulative notifications.

---

## Goals

1. **Phase 0 — Foundation** (Weeks 1-6): Business setup, learn Roblox Studio, validate the educational game concept
2. **Phase 1 — Roblox MVP** (Weeks 7-20): Ship the free educational idle game, target D1 retention >= 20%
3. **Phase 2 — Growth** (Weeks 21-40): Cosmetic-only monetization, educator outreach, reach $500+/month
4. **Phase 3 — Portfolio Expansion** (Weeks 41-78): Standalone Godot version for schools and Steam

## Repo Structure

```
RB.Game/
├── research/               Strategy & market research
│   ├── 01-strategic-foundation.md
│   ├── 02-reality-check.md
│   └── 03-execution-playbook.md
├── roblox/                 Roblox game (Phase 1-2)
│   ├── src/
│   │   ├── server/         ServerScriptService modules
│   │   ├── client/         StarterPlayerScripts modules
│   │   └── shared/         ReplicatedStorage modules
│   └── assets/             Art, sound, UI assets
├── godot/                  Standalone game (Phase 3)
│   ├── src/                GDScript source
│   ├── assets/             Art, sound, UI assets
│   └── scenes/             Godot scene files
├── marketing/              Marketing & discovery
│   ├── tiktok/             Short-form video content
│   ├── steam/              Store page assets & trailers
│   └── influencers/        Outreach tracking
├── community/              Community management
│   └── discord/            Server setup & resources
├── business/               Business & legal
│   ├── legal/              Trademarks, LLC, COPPA
│   └── finance/            Budget tracking, tax prep
└── docs/                   Plans & guides
    └── roadmap.md          Phase-gated roadmap tracker
```

## Key Principles

- **Education first** — Every mechanic teaches something real; science notes unlock through play
- **Anti-dark-pattern** — Transparent odds, no FOMO timers, celebratory notifications, zero pay-to-win
- **Viral through joy** — Discoveries shared openly; players celebrate together, not compete
- **Scalable by default** — Roblox handles all infrastructure; zero deployment complexity
- **Ship small, ship fast** — 60-80 hour MVPs, not multi-year passion projects
- **Ethical monetization** — Cosmetics only: cauldron skins, lab decorations, no gameplay advantage
- **Systems over content** — 4 ingredients × 10 recipes × 5 rarities = hundreds of unique outcomes

## Tech Stack

| Tool | Purpose |
|------|---------|
| Roblox Studio / Luau | Phase 1-2 game development |
| Godot 4 / GDScript | Phase 3 standalone game |
| ProfileService | Roblox data persistence |
| MagicaVoxel | Voxel art (free) |
| Leonardo AI | AI-generated game assets |
| BFXR2 / Bosca Ceoil Blue | Sound effects & music (free) |
| GameAnalytics | Player analytics (free) |
| Discord | Community hub |
| TikTok / Reddit | Discovery & marketing |

## Educational Science Map

| Ingredient | Real Science | Recipe Using It | Science Unlocked |
|---|---|---|---|
| Moonpetal | Bioluminescence / reflected light | Lunar Elixir | Resonance cavities, lasers |
| Fireroot | Geothermal energy | Blazing Tonic | Thermal runaway |
| Shadowmoss | Light absorption / Vantablack | Void Essence | Total light absorption |
| Starbloom | Nuclear fusion / spectroscopy | Celestial Brew | Prisms, visible spectrum |
| Moonpetal + Fireroot | — | Twilight Potion | Convection, weather |
| Moonpetal + Shadowmoss | — | Phantom Draught | Infrared radiation |
| Moonpetal + Starbloom | — | Astral Serum | Laser coherence |
| Fireroot + Shadowmoss | — | Infernal Mix | Exothermic reactions |
| Fireroot + Starbloom | — | Solar Nectar | Solar + wind energy |
| Shadowmoss + Starbloom | — | Eclipse Tincture | Solar corona / eclipses |

## Research

The `research/` folder contains three comprehensive reports:

1. **Strategic Foundation** — Platform economics, genre selection, ethical monetization framework, art strategy, IP & brand building
2. **Reality Check** — Market failure rates, Roblox platform risks, retention benchmarks, burnout prevention, technical architecture
3. **Execution Playbook** — Phase-gated 18-month plan with go/no-go criteria, weekly schedules, financial projections, risk registry
