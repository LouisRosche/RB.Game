# Audio Assets — Alchemy Academy

Replace all placeholder IDs in `src/client/Controllers/SoundController.luau`
before the public launch. This document lists every required sound, its design
intent, and suggested free sources.

---

## How to upload audio to Roblox

1. Creator Hub → **Create** → **Audio** → **Upload Audio**
2. Choose your `.mp3` or `.ogg` file (max 7 MB per file)
3. Copy the resulting `rbxassetid://XXXXXXXXX` string
4. Paste it into `SoundController.luau` in the `SFX_IDS` table

> Roblox requires audio to be owned by the account that publishes the game,
> or licensed via the Audio Marketplace. Using Marketplace audio is fine for
> testing; upload your own files for release to avoid potential takedowns.

---

## Required assets

### Background music (`SFX_IDS.Music`)

| Property | Value |
|----------|-------|
| Feel | Calm, whimsical, slightly mysterious — "cosy lab" |
| Tempo | 80–100 BPM, gentle arpeggios or ambient pads |
| Length | 90+ seconds loopable (clean loop point) |
| Volume target | -20 dBFS (it plays under SFX) |

**Free sources:**
- [Bosca Ceoil Blue](https://boscaceoil.net/) — compose a simple loop in-browser, free, MIT-compatible
- [OpenGameArt.org](https://opengameart.org/) → filter by "music" + CC0 licence
- Roblox Audio Marketplace — search "ambient fantasy loop" (filter: free)

---

### `PlantSeed` — soft soil drop

Heard when the player plants a seed. Should feel satisfying and tactile.

| Property | Value |
|----------|-------|
| Duration | ~0.3 s |
| Tone | Low thud or "plop" — earthy, not metallic |

**Free sources:**
- BFXR2 (online) → Powerup/pickup category, lower pitch — export as WAV, convert to MP3
- Freesound.org: search "seed plant" or "soil drop" (CC0 filter)

---

### `Harvest` — plant pop / collect

Heard on every harvest, before the rarity sting plays.

| Property | Value |
|----------|-------|
| Duration | ~0.4 s |
| Tone | Light "pop" or "pluck" — positive, quick |

**Free sources:**
- BFXR2 → Pickup/coin, raise pitch slightly
- Freesound.org: "pop" or "plant harvest" (CC0)

---

### Rarity stings (play 0.4 s after `Harvest`)

Five distinct sounds, escalating in drama. Players learn to associate sound
with rarity before they see the notification text.

| Key | Rarity | Feel | Duration |
|-----|--------|------|----------|
| `RarityCommon` | Common (60%) | Neutral "ding" | ~0.3 s |
| `RarityUncommon` | Uncommon (25%) | Upbeat two-note chime | ~0.5 s |
| `RarityRare` | Rare (10%) | Magical sparkle ascending | ~0.7 s |
| `RarityEpic` | Epic (4%) | Short fanfare — triumphant | ~1.0 s |
| `RarityLegendary` | Legendary (1%) | Full celebratory fanfare — gold / choir feel | ~1.5 s |

**Approach:** Create all five in BFXR2 (Powerup category) and vary:
- Pitch (Common low → Legendary high)
- Wave count / reverb tail
- Number of harmonics

---

### `BrewStart` — cauldron bubble

Heard when the player confirms a brewing action.

| Property | Value |
|----------|-------|
| Duration | ~0.5 s |
| Tone | Liquid bubbling, slightly magical |

**Free sources:**
- Freesound.org: "cauldron" or "bubbling liquid" (CC0)
- BFXR2 → "Blip/Select" with low pitch and wobble

---

### `BrewComplete` — potion chime

Heard when the brew timer finishes (success feedback).

| Property | Value |
|----------|-------|
| Duration | ~0.6 s |
| Tone | Clear ascending chime — "ta-da" without being obnoxious |

**Free sources:**
- BFXR2 → Powerup, medium pitch, short sustain

---

### `Sell` — coin clink

Heard when the player sells a potion.

| Property | Value |
|----------|-------|
| Duration | ~0.4 s |
| Tone | Coin drop / register ding — classic satisfying sell |

**Free sources:**
- BFXR2 → Pickup, high pitch metallic
- Freesound.org: "coin" (CC0)

---

### `Upgrade` — level-up chime

Heard when lab or cauldron is upgraded.

| Property | Value |
|----------|-------|
| Duration | ~0.8 s |
| Tone | Ascending multi-note — bigger than BrewComplete, marks progression |

**Free sources:**
- BFXR2 → Powerup, three-note arpeggio setting
- OpenGameArt.org: "level up" (CC0)

---

### `Discovery` — recipe discovery fanfare

Heard (plus particles) when a new recipe is found for the first time.
This is the most important SFX moment in the game — make it memorable.

| Property | Value |
|----------|-------|
| Duration | 1.5–2.5 s |
| Tone | Triumphant, warm, celebratory. Think "eureka!" not "achievement unlocked" |

**Free sources:**
- Compose in Bosca Ceoil: ascending major scale ending on high octave
- OpenGameArt.org: "discovery" or "success fanfare" (CC0)

---

### `Notification` — soft ping

Heard when any server notification arrives (not rarity-related).

| Property | Value |
|----------|-------|
| Duration | ~0.2 s |
| Tone | Subtle "ding" — informational, not alarming |

**Free sources:**
- BFXR2 → Blip/Select, very short, high pitch

---

## Checklist

- [ ] Background music uploaded — ID pasted into `SFX_IDS.Music`
- [ ] `PlantSeed` uploaded and ID updated
- [ ] `Harvest` uploaded and ID updated
- [ ] `RarityCommon` uploaded and ID updated
- [ ] `RarityUncommon` uploaded and ID updated
- [ ] `RarityRare` uploaded and ID updated
- [ ] `RarityEpic` uploaded and ID updated
- [ ] `RarityLegendary` uploaded and ID updated
- [ ] `BrewStart` uploaded and ID updated
- [ ] `BrewComplete` uploaded and ID updated
- [ ] `Sell` uploaded and ID updated
- [ ] `Upgrade` uploaded and ID updated
- [ ] `Discovery` uploaded and ID updated
- [ ] `Notification` uploaded and ID updated
- [ ] Playtested all sounds in Studio at default volume
- [ ] Confirmed no copyrighted audio (all CC0 / own work)
