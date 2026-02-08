# Potion Lab -- Game Design Document (Vertical Slice)

**Title:** Potion Lab (working title)
**Platform:** Roblox
**Genre:** Idle Tycoon / Simulator
**Target Audience:** Roblox core demographic (ages 8-16)
**Development Time:** 8-12 weeks (60-80 hours)
**Monetization (Phase 2):** Cosmetic lab decorations, cauldron skins, bottle styles, convenience passes

---

## Core Loop

1. **Buy** ingredient seeds from the shop (spend gold)
2. **Plant** seeds in growing plots
3. **Wait** for ingredients to grow (idle mechanic -- grows even offline)
4. **Harvest** ingredients (mutation rarity rolled at harvest: Common to Legendary)
5. **Brew** -- combine 2 ingredients at the cauldron to make a potion
6. **Sell** potions for gold
7. **Upgrade** -- buy rarer seeds, more plots, better cauldrons
8. **Repeat** with higher-tier ingredients and rarer mutations

### Retention Hooks

- "What rarity did I get?" at harvest
- "What potion does this combo make?" when discovering recipes
- "How much is it worth?" when rare mutations create high-value potions

---

## Ingredients (4 for vertical slice)

| Ingredient  | Color      | Growth Time | Seed Cost | Base Value |
| ----------- | ---------- | ----------- | --------- | ---------- |
| Moonpetal   | Blue       | 30s         | 5g        | 10g        |
| Fireroot    | Red/Orange | 45s         | 10g       | 15g        |
| Shadowmoss  | Purple     | 60s         | 20g       | 20g        |
| Starbloom   | Gold       | 90s         | 40g       | 30g        |

---

## Mutation System

Rolled at harvest. Higher rarity = higher multiplier on potion value.

| Tier      | Chance | Value Multiplier | Color  |
| --------- | ------ | ---------------- | ------ |
| Common    | 60%    | 1x               | Gray   |
| Uncommon  | 25%    | 2x               | Green  |
| Rare      | 10%    | 5x               | Blue   |
| Epic      | 4%     | 15x              | Purple |
| Legendary | 1%     | 50x              | Gold   |

---

## Recipes (10 potions)

### Pure potions (same ingredient x2)

| Ingredient A | Ingredient B | Potion          | Base Value |
| ------------ | ------------ | --------------- | ---------- |
| Moonpetal    | Moonpetal    | Lunar Elixir    | 25g        |
| Fireroot     | Fireroot     | Blazing Tonic   | 35g        |
| Shadowmoss   | Shadowmoss   | Void Essence    | 50g        |
| Starbloom    | Starbloom    | Celestial Brew  | 75g        |

### Combination potions

| Ingredient A | Ingredient B | Potion            | Base Value |
| ------------ | ------------ | ----------------- | ---------- |
| Moonpetal    | Fireroot     | Twilight Potion   | 30g        |
| Moonpetal    | Shadowmoss   | Phantom Draught   | 40g        |
| Moonpetal    | Starbloom    | Astral Serum      | 50g        |
| Fireroot     | Shadowmoss   | Infernal Mix      | 45g        |
| Fireroot     | Starbloom    | Solar Nectar      | 55g        |
| Shadowmoss   | Starbloom    | Eclipse Tincture  | 65g        |

### Value Formula

```
Final potion value = base value x ingredient1 rarity multiplier x ingredient2 rarity multiplier x cauldron bonus
```

Example: Celestial Brew with Epic Starbloom (15x) + Legendary Starbloom (50x) in Silver cauldron (1.25x):
75 x 15 x 50 x 1.25 = **70,312 gold**

---

## Progression

### Lab Levels

| Level | Name       | Plots | Cost    |
| ----- | ---------- | ----- | ------- |
| 1     | Starter    | 2     | Free    |
| 2     | Apprentice | 4     | 500g    |
| 3     | Alchemist  | 6     | 2,000g  |

### Cauldron Levels

| Level | Name   | Brew Time | Value Bonus | Cost    |
| ----- | ------ | --------- | ----------- | ------- |
| 1     | Basic  | 10s       | 1.0x        | Free    |
| 2     | Copper | 7s        | 1.1x        | 300g    |
| 3     | Silver | 4s        | 1.25x       | 1,500g  |

---

## Social Mechanics (vertical slice)

- Each player has their own visible lab area in the world
- Player name displayed above their lab
- Leaderboard: Most Total Gold Earned, Most Potions Brewed
- Visiting: players can walk to and view other players' labs
- Future (Phase 2): trading ingredients/potions between players

---

## Vertical Slice Scope

### What's IN

- Complete core loop (buy, plant, grow, harvest, brew, sell, upgrade)
- 4 ingredients with mutation system
- 10 potion recipes with combinatorial value system
- 3 lab upgrade tiers + 3 cauldron upgrade tiers
- Basic UI: HUD, seed shop, brewing panel, sell panel, upgrade options
- Data persistence (player progress saved across sessions)
- Offline growth (plants continue growing while logged out)
- ProximityPrompt-based interaction
- Notification system for feedback
- Multi-player labs visible in shared world

### What's OUT (deferred to Phase 2+)

- Monetization (cosmetic shop, game passes)
- Weather events affecting mutation rates
- Trading between players
- Seasonal content / battle pass
- Sound design
- Tutorial / guided onboarding (beyond basic prompts)
- Localization (infrastructure in place, translations deferred)
- Advanced visual polish (lighting, post-processing, particles beyond basic)
- Leaderboard UI (data tracked, display deferred)

---

## Player First Session Flow

**Target: player understands the loop within 30 seconds.**

1. Player spawns at their empty lab
2. They see 2 empty plots, a cauldron, and a shop station
3. ProximityPrompt on empty plot says "Plant" -- opens seed selection
4. Player buys cheapest seed (Moonpetal, 5g out of starting 100g)
5. Seed starts growing -- visual feedback (small sprout appears, grows over 30s)
6. Player plants second plot while waiting
7. First plant ready -- "Harvest" prompt -- player harvests -- "You harvested an Uncommon Moonpetal!" notification
8. Second harvest -- now has 2 ingredients
9. Clicks cauldron -- "Brew" -- selects 2 ingredients -- brews Lunar Elixir
10. Clicks sell station -- sells potion -- gold increases
11. Player understands the loop and is hooked on the "what rarity will I get?" dopamine

---

## Retention Targets

| Metric             | Minimum (Go) | Target |
| ------------------ | ------------ | ------ |
| D1 Retention       | 20%          | 30%    |
| D7 Retention       | 5%           | 10%    |
| Avg Session Length  | 8 min        | 15 min |
| Sessions/Week      | 1.5          | 2.5    |

---

## Technical Architecture

- **Single-Script Architecture:** one ServerScript + one LocalScript requiring ModuleScripts
- **Rojo** for filesystem to Studio sync
- **Data persistence:** DataStoreService (upgrade to ProfileService post-vertical-slice)
- **Server-authoritative:** all game logic runs on server, client is display-only
- **RemoteEvents** for client-to-server actions, server-to-client state sync
- **Full state sync pattern:** server sends complete player state after every action

---

## Competitive Positioning

The "Grow a ___" idle tycoon formula is proven (#1 on Roblox in 2025 via Grow a Garden). Existing themes that are TAKEN: garden, crystals, fish, farms, ducks, beehives, candy, brainrot.

Potion Lab differentiates through:

1. **Combinatorial depth** -- 10 ingredients x 5 rarities x 10 recipes = thousands of unique outcomes from minimal content. Systems over content.
2. **Fantasy/alchemy theme** -- universally appealing to Roblox demographic, zero direct competitors in "Grow a" format.
3. **Discovery mechanic** -- "What potion does this combo make?" adds exploration beyond pure idle waiting.
4. **Ethical monetization fit** -- lab decorations, cauldron skins, bottle cosmetics are natural and non-pay-to-win.
