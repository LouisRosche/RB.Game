# Legal Checklist — Alchemy Academy

Last updated: 2026-03-20

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
  - Discord community is 13+ only — do NOT direct under-13 players to Discord
  - State age requirement clearly in any link to the Discord server
- [ ] **CARU compliance** (Children's Advertising Review Unit):
  - Game targets ages 8-16 and has in-game purchases — CARU guidelines apply
  - No false urgency, no pressure tactics, no misleading product descriptions
  - Purchase prompts must clearly state cost in Robux with USD equivalent
  - Cosmetic-only model satisfies CARU's "no exploitation of children's inexperience" standard
- [ ] **Do NOT** store any player data outside of Roblox DataStore/ProfileService
  - No external databases, no third-party analytics SDKs that collect PII
- [ ] **PolicyService integration**: Call `PolicyService:GetPolicyInfoForPlayerAsync()` on player join
  - Respect `ArePaidRandomItemsRestricted` (precaution even without loot boxes)
  - Respect `AllowedExternalLinkReferences` before showing Discord links
  - Respect `IsPaidItemTradingAllowed` for any future trading features

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
- [ ] Add in-game refund notice in shop UI:
  > "All purchases are final. Roblox does not offer refunds for in-game items.
  > For billing issues, contact Roblox Support at roblox.com/support."
- [ ] **FTC Endorsement Guidelines**: Any paid/sponsored influencer content must include
  clear disclosure (#ad, #sponsored, or equivalent). See `marketing/influencers/outreach-template.md`.

---

## Phase 3 — Steam Launch

### Trademark
- [ ] **Search existing trademarks**: USPTO TESS database (tess.uspto.gov) for "Alchemy Academy"
  - Also check EU EUIPO and UK IPO if targeting those markets
- [ ] **File USPTO trademark application**:
  - Class 9: Computer software (covers downloadable games)
  - Class 41: Entertainment services (covers online games)
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
- [ ] **Privacy Policy**: Draft at `business/legal/privacy-policy.md`. Publish at alchemyacademy.game/privacy.
  - Link from Steam store page, Roblox game description, and Discord server
  - Covers COPPA, GDPR, and CCPA obligations
- [ ] **Terms of Service**: Draft at `business/legal/terms-of-service.md`. Publish alongside privacy policy.
- [ ] **Refund Policy**: Steam's standard 2-hour/14-day policy applies automatically
- [ ] **GDPR**: Game doesn't collect personal data beyond what Steam collects → Steam handles compliance.
  If you add any analytics SDK later, review GDPR obligations.
- [ ] **CCPA** (California Consumer Privacy Act):
  - Applies if: 100K+ California users/devices/households OR $25M+ revenue
  - Current design collects no personal information — compliant by default
  - If custom analytics are added, add a "Do Not Sell My Personal Information" link
  - Monitor thresholds as player count grows

### Age Rating (PEGI/ESRB)
- [ ] Self-rate via IARC (free, integrated into Steamworks)
- [ ] Ensure rating is displayed in all marketing materials before launch

### UK Age Appropriate Design Code (AADC / Children's Code)
- [ ] Review the 15 standards of the UK AADC (ico.org.uk/for-organisations/childrens-code)
- [ ] Confirm: no behavioural profiling of under-18 users
- [ ] Confirm: privacy-protective defaults are enabled (no opt-in tracking)
- [ ] Confirm: no nudge techniques or dark patterns in purchase flows
- [ ] Confirm: Data Protection Impact Assessment (DPIA) completed for child-accessible features
- [ ] Document AADC compliance in privacy policy (Section 4.4)

### International Data Protection (monitor as player base grows)
- [ ] **Brazil LGPD** (Lei Geral de Proteção de Dados): If significant Brazilian player base develops, review consent requirements for under-18 users (requires parental consent for under-12s, best-interest standard for 12-18). Appoint a DPO (encarregado) if processing personal data.
- [ ] **South Korea PIPA** (Personal Information Protection Act): If publishing on Korean platforms, comply with data localization requirements. Stricter parental consent rules for under-14s. Korean Game Rating Board (GRB) rating required.
- [ ] **China PIPL** (Personal Information Protection Law): If game becomes accessible in mainland China, requires separate consent for minors under 14, data localization, and mandatory security assessment for cross-border data transfers. Note: China also restricts gaming hours for minors.
- [ ] **Japan APPI** (Act on Protection of Personal Information): Minimal additional obligations if no PII is collected. Monitor for changes.
- [ ] **Australia Privacy Act**: Online Privacy Code for social media/gaming services. If significant Australian player base, review children's privacy obligations.

---

## Ongoing (all phases)

- [ ] Check Roblox ToS for updates — they change frequently, ~4x per year
- [ ] Review DevEx payment receipts against bank deposits quarterly
- [ ] File annual LLC report with Wyoming SOS ($52/yr)
- [ ] File annual tax return by April 15 (or request extension by April 15)
- [ ] Review Privacy Policy and ToS annually or when data practices change
- [ ] Monitor GDPR, CCPA/CPRA, UK AADC regulatory updates for changes affecting children's games
- [ ] Maintain data breach response plan — test notification procedures annually
- [ ] Verify all contact emails (legal@alchemyacademy.game) are active and monitored before publishing legal docs
- [ ] Review influencer partnerships for FTC compliance — audit disclosure practices quarterly

---

## Related Documents

- `business/legal/privacy-policy.md` — Privacy Policy (publish at domain/privacy)
- `business/legal/terms-of-service.md` — Terms of Service (publish at domain/terms)
- `business/finance/budget.md` — Budget and tax planning
- `docs/trademark-domain-research.md` — Trademark search methodology and candidates

---

## Resources

- Wyoming SOS filing: wyoming.gov/sos
- IRS EIN: irs.gov/businesses/small-businesses-self-employed/apply-for-an-employer-identification-number-ein-online
- USPTO TESS: tess.uspto.gov
- CARU Self-Regulatory Program: bbbprograms.org/programs/all-programs/children-advertising-review-unit
- FTC Endorsement Guides: ftc.gov/legal-library/browse/rules/endorsement-guides
- FTC COPPA Rule: ftc.gov/legal-library/browse/rules/childrens-online-privacy-protection-rule
- Steam IARC: Steamworks > App Admin > Ratings & Reviews
- Roblox DevEx: create.roblox.com/dashboard/devex
- Roblox ToS: en.help.roblox.com/hc/en-us/articles/115004647846
- Roblox PolicyService: create.roblox.com/docs/reference/engine/classes/PolicyService
- UK AADC (Children's Code): ico.org.uk/for-organisations/childrens-code
- GDPR Article 8 (children's consent): gdpr-info.eu/art-8-gdpr
- Brazil LGPD: gov.br/anpd (Autoridade Nacional de Proteção de Dados)
- South Korea PIPA: pipc.go.kr (Personal Information Protection Commission)

---

## Disclaimer

This checklist is general information, not legal advice. Consult a licensed
attorney for specific questions about your jurisdiction or situation, especially
for trademark and business formation decisions.
