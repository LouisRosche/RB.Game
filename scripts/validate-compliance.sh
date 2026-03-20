#!/usr/bin/env bash
# validate-compliance.sh
# CI-runnable compliance validation that enforces legal, monetization, privacy,
# and child-safety invariants discovered during the legal compliance audit.
#
# Runs on raw source files WITHOUT requiring Roblox Studio.
# Exit code: 0 = all checks passed, 1 = one or more checks failed.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$REPO_ROOT/roblox/src"
SHARED="$SRC/shared"
SERVER="$SRC/server"
CLIENT="$SRC/client"
LEGAL="$REPO_ROOT/business/legal"
COMMUNITY="$REPO_ROOT/community"
MARKETING="$REPO_ROOT/marketing"

errors=0
warnings=0

pass() { echo "  PASS  $1"; }
fail() { echo "  FAIL  $1"; errors=$((errors + 1)); }
warn_() { echo "  WARN  $1"; warnings=$((warnings + 1)); }

echo ""
echo "========================================"
echo "  Legal & Compliance Validation"
echo "========================================"
echo ""

#---------------------------------------------------------------------------
# 1. No loot box / gacha / randomized purchase mechanics
#---------------------------------------------------------------------------
echo "[1] No loot box or randomized purchase mechanics"

# Ensure no RandomReward, LootBox, GachaRoll, MysteryBox, or CrateOpen patterns
# Exclude comments (lines starting with -- or containing "no loot boxes" disclaimers)
LOOTBOX=$(grep -rniP '(loot.?box|gacha|mystery.?box|crate.?open|random.?reward.?purchase|spin.?wheel.?purchase)' \
    "$SRC/" 2>/dev/null | grep -v "^\s*--" | grep -v "Tests" | \
    grep -viP '(no loot|no.*mystery|precautionary|transparent)' || true)

if [ -n "$LOOTBOX" ]; then
    fail "Potential loot box / gacha mechanic found in source code:"
    echo "$LOOTBOX" | head -5
else
    pass "No loot box or gacha mechanics detected"
fi

#---------------------------------------------------------------------------
# 2. All cosmetics are purely visual (no stat boosts)
#---------------------------------------------------------------------------
echo "[2] Cosmetics contain no gameplay advantages"

# Check that Cosmetics.luau does not reference gameplay terms in item definitions
# Exclude type annotations (export type) and comment lines
COSM_GAMEPLAY=$(grep -niP '(damage|health|speed|multiplier|boost|xp|experience|attack|defense|armou?r)' \
    "$SHARED/Cosmetics.luau" 2>/dev/null | grep -v "^\s*--" | grep -v "export type" | grep -v "type.*=" || true)

if [ -n "$COSM_GAMEPLAY" ]; then
    fail "Cosmetics.luau may reference gameplay stats:"
    echo "$COSM_GAMEPLAY" | head -5
else
    pass "Cosmetics.luau contains no gameplay advantage keywords"
fi

#---------------------------------------------------------------------------
# 3. Game passes are convenience-only (no exclusive content gating)
#---------------------------------------------------------------------------
echo "[3] Game passes are convenience-only"

# Speed Brew multiplier must be > 0 and < 1 (halves time, doesn't eliminate)
SPEED_MUL=$(grep -oP 'SPEED_BREW_MULTIPLIER\s*=\s*\K[0-9.]+' "$SHARED/Config.luau" 2>/dev/null || true)
if [ -n "$SPEED_MUL" ]; then
    if awk "BEGIN{exit !($SPEED_MUL > 0 && $SPEED_MUL < 1)}" 2>/dev/null; then
        pass "SPEED_BREW_MULTIPLIER ($SPEED_MUL) is a convenience modifier (0 < x < 1)"
    else
        fail "SPEED_BREW_MULTIPLIER ($SPEED_MUL) is outside safe range (0, 1)"
    fi
else
    warn_ "Could not extract SPEED_BREW_MULTIPLIER from Config.luau"
fi

#---------------------------------------------------------------------------
# 4. Each cosmetic category has at least one free item
#---------------------------------------------------------------------------
echo "[4] Each cosmetic category has a free default"

for category in "LabTheme" "CauldronTint" "HarvestParticles"; do
    # Look for blocks where category matches AND price = 0 within surrounding context
    FREE=$(grep -A10 "category.*=.*\"$category\"" "$SHARED/Cosmetics.luau" 2>/dev/null | \
        grep -cP "price\s*=\s*0" 2>/dev/null || true)
    FREE="${FREE:-0}"
    # Trim whitespace
    FREE=$(echo "$FREE" | tr -d '[:space:]')
    if [ "$FREE" -gt 0 ] 2>/dev/null; then
        pass "$category has free item(s)"
    else
        fail "$category has no free item — violates anti-dark-pattern policy"
    fi
done

#---------------------------------------------------------------------------
# 5. Mutation odds are transparent (SHOW_MUTATION_ODDS = true)
#---------------------------------------------------------------------------
echo "[5] Mutation odds transparency"

ODDS_FLAG=$(grep -oP 'SHOW_MUTATION_ODDS\s*=\s*\K\w+' "$SHARED/Config.luau" 2>/dev/null || true)
if [ "$ODDS_FLAG" = "true" ]; then
    pass "SHOW_MUTATION_ODDS is true (transparent odds displayed in journal)"
elif [ "$ODDS_FLAG" = "false" ]; then
    fail "SHOW_MUTATION_ODDS is false — violates anti-dark-pattern transparency requirement"
else
    warn_ "Could not determine SHOW_MUTATION_ODDS value"
fi

#---------------------------------------------------------------------------
# 6. Mutation tier chances sum to 1.0 (no hidden probabilities)
#---------------------------------------------------------------------------
echo "[6] Mutation tier chances sum to 1.0"

CHANCES=$(grep -oP 'chance\s*=\s*\K[0-9.]+' "$SHARED/Config.luau" 2>/dev/null || true)
if [ -n "$CHANCES" ]; then
    SUM=$(echo "$CHANCES" | awk '{s+=$1} END {printf "%.4f", s}')
    DIFF=$(echo "$SUM" | awk '{d = $1 - 1.0; if (d < 0) d = -d; print d}')
    if awk "BEGIN{exit !($DIFF < 0.001)}" 2>/dev/null; then
        pass "Mutation tier chances sum to $SUM (within tolerance of 1.0)"
    else
        fail "Mutation tier chances sum to $SUM (expected 1.0)"
    fi
else
    warn_ "Could not extract mutation tier chances"
fi

#---------------------------------------------------------------------------
# 7. No PII collection in data template
#---------------------------------------------------------------------------
echo "[7] No PII fields in data template"

PII_FIELDS=$(grep -niP '(email|phone|address|firstName|lastName|birthday|dateOfBirth|realName|ipAddress|deviceId|location)' \
    "$SERVER/Services/DataService.luau" 2>/dev/null | grep -v "^\s*--" || true)

if [ -n "$PII_FIELDS" ]; then
    fail "Potential PII field in DataService.luau:"
    echo "$PII_FIELDS" | head -5
else
    pass "No PII fields found in player data template"
fi

#---------------------------------------------------------------------------
# 8. No third-party analytics SDKs
#---------------------------------------------------------------------------
echo "[8] No third-party analytics SDKs"

THIRD_PARTY=$(grep -rniP '(google.?analytics|mixpanel|amplitude|segment|firebase|appsflyer|adjust\.io|HttpService.*analytics)' \
    "$SRC/" 2>/dev/null | grep -v "^\s*--" || true)

if [ -n "$THIRD_PARTY" ]; then
    fail "Third-party analytics SDK reference found:"
    echo "$THIRD_PARTY" | head -5
else
    pass "No third-party analytics SDKs — uses only Roblox native AnalyticsService"
fi

#---------------------------------------------------------------------------
# 9. GDPR right-to-erasure support (AddUserId call exists)
#---------------------------------------------------------------------------
echo "[9] GDPR right-to-erasure support"

ADD_USERID=$(grep -c "AddUserId" "$SERVER/Services/DataService.luau" 2>/dev/null || echo "0")
if [ "$ADD_USERID" -gt 0 ]; then
    pass "DataService calls profile:AddUserId() for GDPR erasure support"
else
    fail "DataService missing AddUserId() call — GDPR right-to-erasure not supported"
fi

#---------------------------------------------------------------------------
# 10. Server-authoritative architecture (no client-side economy logic)
#---------------------------------------------------------------------------
echo "[10] Server-authoritative architecture"

# Check that client code does not directly modify economy values
CLIENT_ECON=$(grep -rniP '(data\.Essence\s*=|data\.LabLevel\s*=|data\.CauldronLevel\s*=|data\.OwnedPasses)' \
    "$CLIENT/" 2>/dev/null | grep -v "^\s*--" || true)

if [ -n "$CLIENT_ECON" ]; then
    fail "Client code directly modifies economy data (server-authoritative violation):"
    echo "$CLIENT_ECON" | head -5
else
    pass "No client-side economy modifications — server-authoritative enforced"
fi

#---------------------------------------------------------------------------
# 11. ProcessReceipt saves before granting (purchase safety)
#---------------------------------------------------------------------------
echo "[11] ProcessReceipt saves before granting purchase"

SAVE_BEFORE_GRANT=$(grep -A2 "saveData" "$SERVER/Services/MonetizationService.luau" 2>/dev/null | \
    grep -cP "PurchaseGranted" 2>/dev/null || true)
SAVE_BEFORE_GRANT="${SAVE_BEFORE_GRANT:-0}"
SAVE_BEFORE_GRANT=$(echo "$SAVE_BEFORE_GRANT" | tr -d '[:space:]')

if [ "$SAVE_BEFORE_GRANT" -gt 0 ]; then
    pass "MonetizationService saves data before returning PurchaseGranted"
else
    # Looser check: both saveData and PurchaseGranted exist in the function
    HAS_SAVE=$(grep -c "saveData" "$SERVER/Services/MonetizationService.luau" 2>/dev/null || true)
    HAS_SAVE="${HAS_SAVE:-0}"
    HAS_GRANT=$(grep -c "PurchaseGranted" "$SERVER/Services/MonetizationService.luau" 2>/dev/null || true)
    HAS_GRANT="${HAS_GRANT:-0}"
    if [ "$HAS_SAVE" -gt 0 ] && [ "$HAS_GRANT" -gt 0 ]; then
        pass "MonetizationService contains both saveData and PurchaseGranted calls"
    else
        fail "MonetizationService may not save before granting purchase"
    fi
fi

#---------------------------------------------------------------------------
# 12. Ad cooldown prevents spam (>= 60 seconds)
#---------------------------------------------------------------------------
echo "[12] Rewarded ad cooldown prevents spam"

AD_COOLDOWN=$(grep -oP 'AD_COOLDOWN_SECONDS\s*=\s*\K[0-9]+' "$SHARED/Config.luau" 2>/dev/null || true)
if [ -n "$AD_COOLDOWN" ]; then
    if [ "$AD_COOLDOWN" -ge 60 ]; then
        pass "AD_COOLDOWN_SECONDS = $AD_COOLDOWN (>= 60s minimum)"
    else
        fail "AD_COOLDOWN_SECONDS = $AD_COOLDOWN (must be >= 60 to prevent ad spam)"
    fi
else
    warn_ "Could not extract AD_COOLDOWN_SECONDS"
fi

#---------------------------------------------------------------------------
# 13. Ad reward is meaningful but not game-breaking
#---------------------------------------------------------------------------
echo "[13] Ad reward balance check"

AD_REWARD=$(grep -oP 'AD_REWARD_ESSENCE\s*=\s*\K[0-9]+' "$SHARED/Config.luau" 2>/dev/null || true)
if [ -n "$AD_REWARD" ]; then
    if [ "$AD_REWARD" -ge 10 ] && [ "$AD_REWARD" -le 500 ]; then
        pass "AD_REWARD_ESSENCE = $AD_REWARD (within safe range 10–500)"
    else
        fail "AD_REWARD_ESSENCE = $AD_REWARD (outside safe range 10–500)"
    fi
else
    warn_ "Could not extract AD_REWARD_ESSENCE"
fi

#---------------------------------------------------------------------------
# 14. Privacy policy required sections
#---------------------------------------------------------------------------
echo "[14] Privacy policy completeness"

PRIVACY="$LEGAL/privacy-policy.md"
if [ -f "$PRIVACY" ]; then
    missing_sections=0
    for section in "COPPA" "GDPR" "CCPA" "data minimization" "right to erasure" "data breach"; do
        if ! grep -qi "$section" "$PRIVACY" 2>/dev/null; then
            fail "Privacy policy missing required section: $section"
            missing_sections=$((missing_sections + 1))
        fi
    done
    if [ "$missing_sections" -eq 0 ]; then
        pass "Privacy policy covers all required legal frameworks"
    fi
else
    fail "Privacy policy file not found: $PRIVACY"
fi

#---------------------------------------------------------------------------
# 15. Terms of service required sections
#---------------------------------------------------------------------------
echo "[15] Terms of service completeness"

TOS="$LEGAL/terms-of-service.md"
if [ -f "$TOS" ]; then
    missing_sections=0
    for section in "refund" "virtual" "loot box" "cheat" "content creation"; do
        if ! grep -qi "$section" "$TOS" 2>/dev/null; then
            fail "Terms of service missing required section: $section"
            missing_sections=$((missing_sections + 1))
        fi
    done
    if [ "$missing_sections" -eq 0 ]; then
        pass "Terms of service covers all required sections"
    fi
else
    fail "Terms of service file not found: $TOS"
fi

#---------------------------------------------------------------------------
# 16. PolicyService integration (client respects platform restrictions)
#---------------------------------------------------------------------------
echo "[16] PolicyService integration"

POLICY_CHECK=$(grep -rlc "PolicyService\|GetPolicyInfoForPlayerAsync\|AllowedExternalLinkReferences" \
    "$CLIENT/" 2>/dev/null | head -1 || true)

if [ -n "$POLICY_CHECK" ]; then
    pass "Client code integrates with Roblox PolicyService"
else
    warn_ "No PolicyService references found in client code"
fi

#---------------------------------------------------------------------------
# 17. Discord age requirement (13+)
#---------------------------------------------------------------------------
echo "[17] Discord community age requirement"

DISCORD_SETUP="$COMMUNITY/discord/setup.md"
if [ -f "$DISCORD_SETUP" ]; then
    AGE_REQ=$(grep -ci "13" "$DISCORD_SETUP" 2>/dev/null || echo "0")
    if [ "$AGE_REQ" -gt 0 ]; then
        pass "Discord setup mentions 13+ age requirement"
    else
        fail "Discord setup does not mention 13+ age requirement"
    fi
else
    warn_ "Discord setup file not found"
fi

#---------------------------------------------------------------------------
# 18. Influencer outreach FTC compliance
#---------------------------------------------------------------------------
echo "[18] Influencer outreach FTC compliance"

OUTREACH="$MARKETING/influencers/outreach-template.md"
if [ -f "$OUTREACH" ]; then
    FTC_REF=$(grep -ciP '(#ad|#sponsored|FTC|disclosure)' "$OUTREACH" 2>/dev/null || echo "0")
    if [ "$FTC_REF" -gt 0 ]; then
        pass "Influencer outreach template includes FTC disclosure guidance"
    else
        fail "Influencer outreach template missing FTC disclosure guidance"
    fi
else
    warn_ "Influencer outreach template not found"
fi

#---------------------------------------------------------------------------
# 19. No external HTTP requests from game code (data privacy)
#---------------------------------------------------------------------------
echo "[19] No unauthorized external HTTP requests"

HTTP_CALLS=$(grep -rniP '(HttpService:?(Get|Post|Request)|http\.request|fetch\()' \
    "$SRC/" 2>/dev/null | grep -v "^\s*--" || true)

if [ -n "$HTTP_CALLS" ]; then
    fail "External HTTP request found in game code (potential data exfiltration):"
    echo "$HTTP_CALLS" | head -5
else
    pass "No external HTTP requests — all data stays within Roblox ecosystem"
fi

#---------------------------------------------------------------------------
# 20. Session locking (ProfileService) prevents data corruption
#---------------------------------------------------------------------------
echo "[20] Session locking via ProfileService"

SESSION_LOCK=$(grep -c "ListenToRelease" "$SERVER/Services/DataService.luau" 2>/dev/null || echo "0")
PROFILE_SVC=$(grep -c "ProfileService" "$SERVER/Services/DataService.luau" 2>/dev/null || echo "0")

if [ "$SESSION_LOCK" -gt 0 ] && [ "$PROFILE_SVC" -gt 0 ]; then
    pass "DataService uses ProfileService with session locking (ListenToRelease)"
else
    fail "DataService may lack session locking — data corruption risk"
fi

#---------------------------------------------------------------------------
# 21. Offline growth enabled (no FOMO timers)
#---------------------------------------------------------------------------
echo "[21] No FOMO mechanics — offline growth enabled"

OFFLINE=$(grep -oP 'OFFLINE_GROWTH\s*=\s*\K\w+' "$SHARED/Config.luau" 2>/dev/null || true)
if [ "$OFFLINE" = "true" ]; then
    pass "OFFLINE_GROWTH = true (no FOMO pressure on players)"
elif [ "$OFFLINE" = "false" ]; then
    fail "OFFLINE_GROWTH = false — creates FOMO pressure, violates anti-dark-pattern policy"
else
    warn_ "Could not determine OFFLINE_GROWTH value"
fi

#---------------------------------------------------------------------------
# 22. No pay-to-win keywords in server gameplay services
#---------------------------------------------------------------------------
echo "[22] No pay-to-win in gameplay services"

# Ensure GrowthService/EconomyService don't gate progression behind purchases
PAY_GATE=$(grep -rniP '(hasPass|OwnedPasses|GamePasses)' \
    "$SERVER/Services/" 2>/dev/null | \
    grep -v "MonetizationService" | \
    grep -v "^\s*--" | \
    grep -viP '(speed|auto.?harvest|cosmetic|vip|chat.?tag|nameplate)' || true)

if [ -n "$PAY_GATE" ]; then
    warn_ "Game pass checks found outside MonetizationService (verify these are convenience-only):"
    echo "$PAY_GATE" | head -5
else
    pass "Game pass references in gameplay services are limited to convenience features"
fi

#---------------------------------------------------------------------------
# Summary
#---------------------------------------------------------------------------
echo ""
echo "========================================"
if [ "$errors" -eq 0 ]; then
    if [ "$warnings" -gt 0 ]; then
        echo "  ALL PASSED ($warnings warnings)"
    else
        echo "  ALL PASSED"
    fi
    echo "========================================"
    exit 0
else
    echo "  ERRORS: $errors  |  WARNINGS: $warnings"
    echo "========================================"
    exit 1
fi
