# Legal Compliance Audit — Alchemy Academy

**Audit Date:** March 20, 2026
**Auditor:** Automated code + document review
**Scope:** Full codebase, legal documents, marketing materials, community setup
**Status:** PASS with 5 findings (3 fixed, 2 advisory)

---

## Audit Methodology

This audit reviewed:
1. All server-side Luau services (10 modules) for data handling, monetization, and anti-exploit
2. All client-side controllers (6 modules) for PolicyService integration and UI compliance
3. All shared modules (9 modules) for pricing, odds transparency, and string content
4. Legal documents: Privacy Policy, Terms of Service, Legal Checklist
5. Marketing materials: influencer outreach templates, Discord setup, community posts
6. CI/CD pipeline: legal document presence checks, data integrity validation

Frameworks checked: COPPA, CARU, FTC Endorsement Guidelines, GDPR (Article 8), CCPA/CPRA,
UK AADC (Children's Code), Roblox ToS, Belgium/EU loot box regulations.

---

## Summary of Findings

| # | Finding | Severity | Status |
|---|---------|----------|--------|
| 1 | Privacy Policy cross-reference error in Section 4.5 | MEDIUM | **FIXED** |
| 2 | REFUND_NOTICE string claims USD values are displayed but none are shown | MEDIUM | **FIXED** |
| 3 | Missing `ArePaidRandomItemsRestricted` PolicyService check | LOW | **FIXED** |
| 4 | VIP pass benefit "Early access to future VIP-only cosmetics" is undeliverable | LOW | **FIXED** |
| 5 | No Data Protection Impact Assessment (DPIA) document for UK AADC | ADVISORY | OPEN |
| 6 | No formal data breach response plan document | ADVISORY | OPEN |

---

## Detailed Findings

### Finding 1: Privacy Policy Cross-Reference Error

**File:** `business/legal/privacy-policy.md`, Section 4.5
**Issue:** Section 4.5 (Parental Rights) directs parents to "the address listed in Section 9"
for contact information. However, contact information is in Section 10 (Contact Us).
Section 9 is "Changes to This Privacy Policy" which contains no contact details.
**Risk:** Parents unable to locate contact information for data requests → potential
COPPA/GDPR non-compliance if a request goes unanswered.
**Fix:** Updated cross-reference from "Section 9" to "Section 10".

### Finding 2: Misleading REFUND_NOTICE String

**File:** `roblox/src/shared/Strings.luau`, line 145
**Issue:** The `REFUND_NOTICE` string states "approximate USD value displayed" but no
USD equivalent is calculated or shown anywhere in the codebase. Game pass prices in
`GamePasses.luau` and cosmetic prices in `Cosmetics.luau` are Robux-only. The shop UI
(`UIController.luau`) does not perform any Robux-to-USD conversion.
**Risk:** CARU/FTC: Making a factual claim about pricing display that is not implemented
constitutes a misleading product description.
**Fix:** Removed the inaccurate "approximate USD value displayed" clause. The refund
notice now accurately states "Prices shown in Robux."

### Finding 3: Missing ArePaidRandomItemsRestricted Check

**File:** `roblox/src/client/Controllers/UIController.luau`, PolicyService handler
**Issue:** The PolicyService integration checks `AreAdsAllowed` and
`AllowedExternalLinkReferences` but does not check `ArePaidRandomItemsRestricted`.
While Alchemy Academy has no loot boxes, the mutation/rarity system (players buy seeds
→ harvest produces random rarity tiers) could be interpreted as a "paid random item"
in jurisdictions with strict definitions (Belgium, Netherlands).
**Risk:** LOW — the game's transparent odds display and non-randomized purchases
(you always get the ingredient you bought; only rarity varies) make this defensible.
However, checking the flag is a best practice documented in the project's own legal
checklist (`business/legal/checklist.md`, line 43).
**Fix:** Added `ArePaidRandomItemsRestricted` check to the PolicyService handler.
When restricted, the rarity odds display in the Journal is emphasized and a note is
added that all rarity outcomes are cosmetic value multipliers only.

### Finding 4: VIP Pass Undeliverable Benefit

**File:** `roblox/src/shared/GamePasses.luau`, VIP pass definition
**Issue:** The VIP Alchemist pass lists "Early access to future VIP-only cosmetics"
as a benefit. No VIP-exclusive cosmetics exist or are planned in the current roadmap.
CARU Self-Regulatory Program guidelines (§ 112.2) prohibit advertising benefits to
children that may not be delivered.
**Risk:** LOW — the pass is priced at 99 Robux (lowest tier) and the other 3 benefits
are functional. However, promising future content that may never exist is a compliance
risk for a children's product.
**Fix:** Replaced with "Support the developer — thank you!" which is honest, warm,
and makes no undeliverable promise.

### Finding 5: No DPIA Document (Advisory)

**Location:** Missing from `business/legal/`
**Issue:** The UK Age Appropriate Design Code (AADC) Standard 1 requires a Data
Protection Impact Assessment (DPIA) for services likely to be accessed by children
under 18. The legal checklist references this (line 112) but no DPIA document exists.
**Risk:** ADVISORY — the game collects minimal data (Section 2.1 of Privacy Policy)
and relies on platform-level data handling, making the DPIA straightforward to complete.
However, the absence of a formal DPIA could be cited in a regulatory review.
**Recommendation:** Create `business/legal/dpia.md` documenting the minimal data
processing, risk assessment, and mitigations before Phase 3 (Steam launch, which
expands the audience beyond Roblox's existing compliance framework).

### Finding 6: No Data Breach Response Plan (Advisory)

**Location:** Missing from `business/legal/`
**Issue:** The Privacy Policy (Section 8) commits to specific breach notification
timelines (72 hours for GDPR, state law compliance for US). The legal checklist
(line 132) calls for maintaining and testing a breach response plan annually.
No such plan document exists.
**Risk:** ADVISORY — the game stores only non-personal in-game progress data,
making a meaningful breach unlikely. However, the Privacy Policy makes commitments
that should be backed by a documented process.
**Recommendation:** Create `business/legal/breach-response-plan.md` before
monetization goes live (Phase 2), documenting: detection procedures, notification
templates, supervisory authority contacts, and remediation steps.

---

## Compliance Areas Verified (No Issues Found)

### COPPA (Children's Online Privacy Protection Act)
- ✅ No PII collected from any player (Section 2.3 of Privacy Policy)
- ✅ No external databases or third-party analytics SDKs
- ✅ Relies on Roblox platform for age verification and parental consent
- ✅ Discord community explicitly restricted to 13+ with clear notice
- ✅ ProfileService `AddUserId` used for GDPR erasure (not PII collection)

### CARU (Children's Advertising Review Unit)
- ✅ No false urgency or countdown timers on purchase prompts
- ✅ No pressure tactics in notification strings (verified: Strings.luau uses
  celebratory, warm language throughout)
- ✅ Purchase prompts clearly state Robux cost
- ✅ Refund notice displayed in shop UI (UIController.luau:1731-1740)
- ✅ Cosmetic-only monetization — no gameplay advantages for purchase
- ✅ No misleading product descriptions (after Finding 4 fix)

### FTC Endorsement Guidelines
- ✅ Influencer outreach template includes explicit FTC disclosure requirements
- ✅ Content creation license in ToS requires #ad/#sponsored disclosure for paid content
- ✅ Tracking sheet for documenting paid partnerships

### GDPR (General Data Protection Regulation)
- ✅ Legal basis documented (legitimate interest + contract performance)
- ✅ Data minimization: only gameplay progress data stored
- ✅ Right of access, erasure, and portability documented in Privacy Policy
- ✅ `AddUserId` ensures data can be identified for erasure requests
- ✅ Article 8 (children's consent): defers to platform, with cautious treatment
  of AddUserId-linked data

### CCPA/CPRA (California Consumer Privacy Act)
- ✅ No sale or sharing of personal information
- ✅ Rights documented: right to know, right to delete, non-discrimination
- ✅ Threshold monitoring noted in legal checklist

### UK Age Appropriate Design Code (AADC)
- ✅ Best interests: educational game, no exploitation of developmental vulnerabilities
- ✅ Data minimization: minimal data collection (Section 2.1)
- ✅ Default settings: privacy-protective defaults, no tracking
- ✅ Transparency: Privacy Policy written in clear language
- ✅ No detrimental use: data used only for gameplay
- ✅ No nudge techniques: verified in Strings.luau — no dark patterns
- ⚠️ DPIA: not yet documented (Finding 5)

### Roblox Platform Compliance
- ✅ No political content
- ✅ No gambling mechanics (transparent odds, deterministic purchases)
- ✅ Age-appropriate content (educational, ages 8-16)
- ✅ PolicyService integration: `GetPolicyInfoForPlayerAsync` called on join
- ✅ `AreAdsAllowed` respected for rewarded video ads
- ✅ `AllowedExternalLinkReferences` respected for Discord/website links
- ✅ `ArePaidRandomItemsRestricted` now checked (Finding 3 fix)
- ✅ Server-authoritative architecture prevents client-side exploitation
- ✅ Rate limiting on all RemoteEvents (Main.server.luau:69-101)
- ✅ Input type validation on all RemoteEvent handlers

### Anti-Dark-Pattern Design
- ✅ No loot boxes or randomized purchases
- ✅ Transparent mutation odds displayed in Journal
- ✅ Config.SHOW_MUTATION_ODDS = true (cannot be disabled without code change)
- ✅ Offline growth enabled (Config.OFFLINE_GROWTH = true) — no FOMO
- ✅ No time-limited purchase pressure
- ✅ Seasonal content is additive (extra ingredients), not exclusive
- ✅ All notification strings use warm, encouraging language
- ✅ Ad system is opt-in only, with clear cooldown display

### Monetization Integrity
- ✅ ProcessReceipt saves to DataStore before returning PurchaseGranted
- ✅ Duplicate purchase protection (idempotent cosmetic grants)
- ✅ Game pass ownership verified server-side via UserOwnsGamePassAsync
- ✅ Free defaults exist for every cosmetic category
- ✅ Ad rewards granted only after server-verified completion
- ✅ No real-money trading system

### Data Security
- ✅ ProfileService session locking prevents data corruption
- ✅ ListenToRelease handles profile theft gracefully
- ✅ No secrets committed (CI check: `.env`, `credentials*`, `*.pem`, `*.key`)
- ✅ No binary files committed (CI check: `*.rbxl`, `*.exe`, etc.)
- ✅ Player data cleaned up on leave (adCooldowns, adBoostExpiry, lastFire)

---

## Recommendations (Non-Blocking)

1. **Create DPIA document** before Phase 3 Steam launch
2. **Create breach response plan** before Phase 2 monetization goes live
3. **Add Robux-to-USD approximation** in shop UI for full CARU transparency
   (not legally required but recommended in legal checklist)
4. **Register domain and publish legal docs** before first public marketing push
5. **Set up legal@alchemyacademy.game email** before publishing Privacy Policy
6. **Consider adding `IsPaidItemTradingAllowed` check** if trading features are
   ever added (currently correctly absent since no trading exists)

---

## Files Modified in This Audit

| File | Change |
|------|--------|
| `business/legal/privacy-policy.md` | Fixed Section 4.5 cross-reference |
| `roblox/src/shared/Strings.luau` | Fixed misleading REFUND_NOTICE |
| `roblox/src/client/Controllers/UIController.luau` | Added ArePaidRandomItemsRestricted check |
| `roblox/src/shared/GamePasses.luau` | Replaced undeliverable VIP benefit |
| `docs/legal-compliance-audit.md` | This document (new) |
| `docs/audit-report.md` | Updated gaps table with compliance audit results |
