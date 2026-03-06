# Legal Checklist — Alchemy Academy

Last updated: 2026-03-06

Complete Phase 0 items before publishing anything publicly.
Complete Phase 2 items before monetising.

---

## Phase 0 — Foundation (complete before soft launch)

### LLC Formation
- [ ] **Choose state**: Wyoming recommended for solo devs (cheapest fees, no state income tax, strong asset protection)
- [ ] **File Articles of Organisation** with Wyoming SOS: $100 filing fee, online at wyoming.gov/sos
- [ ] **Get an EIN** (Employer Identification Number): free at IRS.gov, takes 5 minutes online
  - Use EIN (not your SSN) for all business accounts and tax forms
- [ ] **Open business bank account**: Mercury or Relay — requires LLC docs + EIN
- [ ] **Registered agent service**: Required for Wyoming LLC if you don't live there. ~$50–120/yr.
  - Options: Northwest Registered Agent, Registered Agents Inc, ZenBusiness

### Operating Agreement
- [ ] Draft a basic single-member LLC Operating Agreement (not required in Wyoming but good practice)
  - States: you are the sole member, all profits go to you, dissolve by your decision
  - Template: free at LegalTemplates.net or Northwest Registered Agent

### Roblox-Specific
- [ ] Read and comply with current **Roblox Terms of Service** (updated frequently — check tos.roblox.com)
  - Key items: no political content, no gambling mechanics, age-appropriate content
  - Our game: compliant as designed (transparent odds, no loot boxes, educational content)
- [ ] **COPPA compliance** (Children's Online Privacy Protection Act):
  - Don't collect personally identifiable information from under-13 users
  - Roblox handles this at the platform level — don't implement your own data collection
  - The in-game Journal and Discord are the only community touchpoints — both are fine
- [ ] **Do NOT** store any player data outside of Roblox DataStore/ProfileService
  - No external databases, no third-party analytics SDKs that collect PII

---

## Phase 2 — Monetisation (complete before enabling game passes)

### Tax Paperwork
- [ ] **Form W-9** (US) or **W-8BEN** (non-US): required by Roblox for DevEx payouts
  - File at creator.roblox.com → Tax Information
- [ ] Set up quarterly estimated tax payments (see business/finance/budget.md)
- [ ] Start using Wave Accounting or similar to track all income and expenses from day 1

### Roblox Monetisation Compliance
- [ ] Game passes and developer products are compliant with Roblox ToS
- [ ] No loot boxes: our cosmetics are direct purchase, not random (compliant with EU/Belgium rules)
- [ ] No pay-to-win: velocity passes and cosmetics only (compliant with FTC guidelines)
- [ ] Prices shown in Robux AND USD equivalent where possible (transparency best practice)
- [ ] Add in-game "Refund Policy" note: Roblox has a no-refund policy by default — inform players in the shop UI

---

## Phase 3 — Steam Launch

### Trademark
- [ ] **Search existing trademarks**: USPTO TESS database (tess.uspto.gov) for "Alchemy Academy"
  - Also check EU EUIPO and UK IPO if targeting those markets
- [ ] **File USPTO trademark application**:
  - Class 41: Entertainment services (covers games)
  - TEAS Plus application: $250/class (lower cost, stricter requirements)
  - TEAS Standard: $350/class (more flexible)
  - Processing time: 8–12 months
  - File at minimum 6 months before Steam launch (ideally 12 months before)
- [ ] **Domain**: Register alchemyacademy.game or .io before filing trademark
  - Cost: ~$10–30/yr depending on TLD

### Steam/Valve Agreements
- [ ] Sign **Steam Distribution Agreement** (in Steamworks — digital, no lawyer needed for basic indie)
- [ ] **IARC rating**: Fill out the content questionnaire in Steamworks
  - Expected: ESRB E (Everyone) or E10+ / PEGI 3 / USK 0
  - Educational content, no violence, no gambling mechanic
- [ ] **Privacy Policy**: Required for Steam. Use iubenda.com or Termly.io to generate one.
  - Publish at: alchemyacademy.game/privacy
  - Link from Steam store page
- [ ] **Refund Policy**: Steam's standard 2-hour/14-day policy applies automatically
- [ ] GDPR: Game doesn't collect personal data beyond what Steam collects → Steam handles compliance.
  If you add any analytics SDK later, review GDPR obligations.

### Age Rating (PEGI/ESRB)
- [ ] Self-rate via IARC (free, integrated into Steamworks)
- [ ] Ensure rating is displayed in all marketing materials before launch

---

## Ongoing (all phases)

- [ ] Check Roblox ToS for updates — they change frequently, ~4x per year
- [ ] Review DevEx payment receipts against bank deposits quarterly
- [ ] File annual LLC report with Wyoming SOS ($52/yr)
- [ ] File annual tax return by April 15 (or request extension by April 15)

---

## Resources

- Wyoming SOS filing: wyoming.gov/sos
- IRS EIN: irs.gov/businesses/small-businesses-self-employed/apply-for-an-employer-identification-number-ein-online
- USPTO TESS: tess.uspto.gov
- Steam IARC: Steamworks > App Admin > Ratings & Reviews
- Roblox DevEx: create.roblox.com/dashboard/devex
- Roblox ToS: en.help.roblox.com/hc/en-us/articles/115004647846

---

## Disclaimer

This checklist is general information, not legal advice. Consult a licensed
attorney for specific questions about your jurisdiction or situation, especially
for trademark and business formation decisions.
