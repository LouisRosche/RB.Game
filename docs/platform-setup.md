# Platform Setup Guide

*Phase 0 checklist items: Roblox developer account, itch.io account, domain name.*
*Complete all three before any public content goes live.*

---

## 1. Roblox Developer Account

### Create the account

1. Go to roblox.com → click **Sign Up**
2. Use a dedicated email address (not your personal one) — this account is the business entity
3. Username: choose something professional or brandable. Suggestions:
   - `AlchemyAcademyDev`
   - `BrewLabStudio`
   - `RBGameStudio`
   - Keep it short — it appears in-game and on the Creator Dashboard
4. Date of birth: enter your real date (affects DevEx eligibility — must be 13+ for DevEx)
5. **Immediately enable 2FA**: Settings → Security → Two-Step Verification → Authenticator App (preferred over SMS)

### Verify your account for DevEx (Developer Exchange)

DevEx is how you convert Robux to USD. Requirements:
- Account age ≥ 30 days
- Email verified
- 30,000+ Robux earned (not purchased)
- No ToS violations
- Premium membership required for first DevEx

Start the 30-day clock now — you will not be able to cash out until then.

### Creator Dashboard

After creating your account, visit create.roblox.com and familiarise yourself with:
- **Creations** — where your published games appear
- **Analytics** — D1/D7 retention, DAU, revenue (critical for Phase 1 go/no-go)
- **Monetisation** → Developer Exchange — where you request payouts
- **Settings** → Tax Information — complete before first DevEx request

### Install the toolchain

```sh
# Install Aftman (toolchain manager)
curl -sSf https://raw.githubusercontent.com/LPGhatguy/aftman/main/scripts/install.sh | sh

# From the roblox/ directory:
cd roblox/
aftman init
aftman add rojo-rbx/rojo
aftman install
```

Or install Rojo directly (see roblox/README.md for alternatives).

---

## 2. itch.io Account

itch.io is used for:
- Demo distribution during Phase 3 (before Steam page is live)
- Building an early community outside Roblox
- Optional: a free devlog page to cross-post with TikTok

### Setup

1. Go to itch.io → Create account
2. Username: match your Roblox username or use `alchemyacademy`
3. Profile page: add a short bio, link your TikTok and Discord
4. No payment setup needed until you actually sell something

### Initial page (optional, Phase 0)

Create a **devlog-only** page now:
- Type: **HTML/Downloadable** (even if no file yet — you can update later)
- Title: "Alchemy Academy"
- Status: **In Development**
- Price: Free
- Add a short description and a placeholder screenshot
- Mark as unlisted until the game is ready

This page will collect followers passively and gives you a link to share.

---

## 3. Domain Name

### Why now

Domains get sniped. Once "Alchemy Academy" gets any public attention, squatters
watch for the name. Register before your first TikTok post.

### Recommended options (in priority order)

| Domain | Estimated Cost | Notes |
|--------|---------------|-------|
| `alchemyacademy.game` | ~$35/yr | Premium `.game` TLD — signals it's a game, memorable |
| `alchemyacademy.io` | ~$40/yr | Tech-credible, widely recognised |
| `alchemyacademy.gg` | ~$20/yr | Popular for games/gaming communities |
| `alchemyacademy.com` | ~$12/yr | Most trusted, hardest to get clean |

Check availability at: namecheap.com, porkbun.com (cheapest renewal rates), or
Cloudflare Registrar (at-cost pricing, no markup).

**Buy at minimum one option.** `alchemyacademy.gg` is the best value if .com
or .game are taken or expensive.

### DNS setup (after buying)

For now, just park the domain — redirect it to your itch.io or Roblox page.
A full website is a Phase 2+ concern.

Use Cloudflare (free) for DNS management even if you buy elsewhere:
- Better DDoS protection if you ever add a backend
- Free SSL certificate
- Easy redirect rules (forward naked domain to www, etc.)

---

## Checklist Summary

| Item | Time | Cost | Action |
|------|------|------|--------|
| Roblox account + 2FA | 15 min | $0 | create.roblox.com |
| Roblox DevEx eligible | 30 days | $0 (waiting period) | auto after account age |
| itch.io account | 10 min | $0 | itch.io |
| Domain name | 10 min | ~$12–40/yr | namecheap.com or porkbun.com |
| **Total** | **~35 min active** | **~$12–40** | |
