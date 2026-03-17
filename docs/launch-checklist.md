# Alchemy Academy — Launch Readiness Checklist

> Last updated: March 16, 2026

## Pre-Launch Blockers (Must Do Before Any Players)

- [ ] Download real ProfileService from GitHub (current file is a stub) — replace `roblox/src/server/Vendor/ProfileService.luau`
- [ ] Upload 13 audio assets to Roblox and replace placeholder IDs in `SoundController.luau` (see `roblox/AUDIO_ASSETS.md`)
- [ ] Create game icon (512x512) and 5 thumbnails (1920x1080) per `docs/store-listing.md`
- [ ] Test full game loop in Roblox Studio (plant -> grow -> harvest -> brew -> sell -> upgrade)
- [ ] Verify ProfileService session-locking works with 2+ test accounts
- [ ] Test all 10 recipes brew correctly with expected value output
- [ ] Test all game passes purchase flow (use sandbox/test mode)
- [ ] Verify tutorial completes without errors for new player

## Soft Launch (Unlisted, 10-20 Testers)

- [ ] Publish game as Unlisted on Roblox
- [ ] Recruit 10-20 testers (friends, DevForum, Discord)
- [ ] Monitor AnalyticsService events for first session funnel
- [ ] Collect qualitative feedback (what confused them, what they liked)
- [ ] Measure actual D1 retention against 20% target
- [ ] Fix top 3 issues from tester feedback
- [ ] Iterate 2-3 times over 1-2 weeks

## Public Launch

- [ ] Set game to Public on Roblox
- [ ] Post DevForum concept feedback (draft in `marketing/community-posts/`)
- [ ] Post Reddit feedback requests (drafts in `marketing/community-posts/`)
- [ ] Create Discord server (plan in `community/discord/setup.md`)
- [ ] Set up TikTok account, begin content calendar (`marketing/tiktok/`)
- [ ] Enable Rewarded Video Ads (if eligible — requires 100K+ visits)
- [ ] Monitor D1, D7, D30 retention daily for first 2 weeks

## Quick-Win: Obby Game

- [ ] Expand `roblox/obby/` with checkpoint system, skip game pass, cosmetic trail shop
- [ ] Create icon and publish as separate experience
- [ ] Use as testbed for monetization mechanics and Roblox publishing workflow
- [ ] Cross-promote Alchemy Academy from obby

## Business & Legal

- [ ] Form LLC (Wyoming, ~$100)
- [ ] Get EIN (free, IRS.gov)
- [ ] Open business bank account
- [ ] Register domain (alchemyacademy.gg or .game)
- [ ] Begin USPTO trademark search for Phase 3

## Roblox Incubator Application (Time-Sensitive)

- [ ] Review program requirements at roblox.com
- [ ] Prepare prototype demo video (Roblox Studio recording)
- [ ] Write application narrative emphasizing: novel alchemy/science mechanic, ethical monetization, educational angle, systems-over-content design
- [ ] Submit application before cohort deadline
