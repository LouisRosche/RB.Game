#!/usr/bin/env bash
# validate-godot-compliance.sh
# CI-runnable compliance validation for the Godot standalone game
# (Alchemy Academy: Origins — Phase 3 Steam launch).
#
# Checks data privacy, anti-dark-pattern design, cross-platform consistency,
# and child-safety invariants in GDScript source files.
#
# Exit code: 0 = all checks passed, 1 = one or more checks failed.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="$REPO_ROOT/godot"
GODOT_SRC="$GODOT/src"
ROBLOX_SHARED="$REPO_ROOT/roblox/src/shared"

errors=0
warnings=0

pass() { echo "  PASS  $1"; }
fail() { echo "  FAIL  $1"; errors=$((errors + 1)); }
warn_() { echo "  WARN  $1"; warnings=$((warnings + 1)); }

echo ""
echo "========================================"
echo "  Godot Compliance Validation"
echo "========================================"
echo ""

#---------------------------------------------------------------------------
# 1. No PII collection in save data
#---------------------------------------------------------------------------
echo "[1] No PII in save data"

PII=$(grep -rniP '(email|phone|address|first_name|last_name|birthday|date_of_birth|real_name|ip_address|device_id|location|password|ssn|social_security)' \
    "$GODOT_SRC/" 2>/dev/null | grep -v "^\s*##" | grep -v "^\s*#" || true)

if [ -n "$PII" ]; then
    fail "Potential PII field in Godot source:"
    echo "$PII" | head -5
else
    pass "No PII fields found in Godot source"
fi

#---------------------------------------------------------------------------
# 2. No external HTTP/network requests (data exfiltration prevention)
#---------------------------------------------------------------------------
echo "[2] No external network requests"

HTTP=$(grep -rniP '(HTTPRequest|http_request|HTTPClient|fetch|StreamPeerTCP|PacketPeerUDP|WebSocketPeer|MultiplayerPeer)' \
    "$GODOT_SRC/" 2>/dev/null | grep -v "^\s*##" | grep -v "^\s*#" || true)

if [ -n "$HTTP" ]; then
    fail "Network request capability found in Godot source (data exfiltration risk):"
    echo "$HTTP" | head -5
else
    pass "No external network requests — single-player local-only"
fi

#---------------------------------------------------------------------------
# 3. Save data uses local paths only (no cloud without consent)
#---------------------------------------------------------------------------
echo "[3] Save data is local-only"

CLOUD=$(grep -rniP '(cloud_save|remote_save|steam_cloud|upload_save|sync_save|SteamCloud)' \
    "$GODOT_SRC/autoload/SaveManager.gd" 2>/dev/null | \
    grep -v "^\s*##" | grep -v "^\s*#" | grep -vi "no cloud" || true)

if [ -n "$CLOUD" ]; then
    warn_ "Cloud save references found in SaveManager.gd (verify consent flow exists):"
    echo "$CLOUD" | head -3
else
    pass "SaveManager uses local paths only (user:// scheme)"
fi

#---------------------------------------------------------------------------
# 4. No loot box / gacha / randomized purchase mechanics
#---------------------------------------------------------------------------
echo "[4] No loot box or gacha mechanics"

LOOTBOX=$(grep -rniP '(loot.?box|gacha|mystery.?box|crate.?open|random.?reward.?purchase|spin.?wheel|microtransaction)' \
    "$GODOT_SRC/" 2>/dev/null | grep -v "^\s*##" | grep -v "^\s*#" || true)

if [ -n "$LOOTBOX" ]; then
    fail "Potential loot box / gacha mechanic in Godot source:"
    echo "$LOOTBOX" | head -5
else
    pass "No loot box or gacha mechanics detected"
fi

#---------------------------------------------------------------------------
# 5. No in-app purchase code (Steam handles purchases externally)
#---------------------------------------------------------------------------
echo "[5] No in-app purchase code"

IAP=$(grep -rniP '(purchase|buy_item|transaction|payment|checkout|iap|in_app_purchase|robux)' \
    "$GODOT_SRC/" 2>/dev/null | grep -v "^\s*##" | grep -v "^\s*#" || true)

if [ -n "$IAP" ]; then
    warn_ "Purchase-related terms found in Godot source (verify these are game-currency only):"
    echo "$IAP" | head -5
else
    pass "No in-app purchase code — standalone game with no microtransactions"
fi

#---------------------------------------------------------------------------
# 6. No FOMO mechanics (countdown timers, limited-time offers)
#---------------------------------------------------------------------------
echo "[6] No FOMO mechanics"

FOMO=$(grep -rniP '(limited.?time|expires?.?in|countdown|hurry|last.?chance|time.?left|daily.?reward|streak|login.?bonus)' \
    "$GODOT_SRC/" 2>/dev/null | grep -v "^\s*##" | grep -v "^\s*#" || true)

if [ -n "$FOMO" ]; then
    fail "Potential FOMO mechanic in Godot source:"
    echo "$FOMO" | head -5
else
    pass "No FOMO mechanics detected"
fi

#---------------------------------------------------------------------------
# 7. No dark pattern UI text (pressure, urgency, shame)
#---------------------------------------------------------------------------
echo "[7] No dark pattern UI text"

DARK=$(grep -rniP '(are you sure you want to miss|don.t miss out|everyone is|your friends|you.ll lose|act now|exclusive offer|only .* left)' \
    "$GODOT_SRC/" 2>/dev/null | grep -v "^\s*##" | grep -v "^\s*#" || true)

if [ -n "$DARK" ]; then
    fail "Dark pattern UI language detected:"
    echo "$DARK" | head -5
else
    pass "No dark pattern language in UI text"
fi

#---------------------------------------------------------------------------
# 8. Inventory caps exist (prevent save file bloat / corruption)
#---------------------------------------------------------------------------
echo "[8] Inventory caps prevent data bloat"

MAX_ING=$(grep -oP 'MAX_INGREDIENTS\s*:=\s*\K[0-9]+' "$GODOT_SRC/autoload/GameState.gd" 2>/dev/null || true)
MAX_POT=$(grep -oP 'MAX_POTIONS\s*:=\s*\K[0-9]+' "$GODOT_SRC/autoload/GameState.gd" 2>/dev/null || true)

if [ -n "$MAX_ING" ] && [ -n "$MAX_POT" ]; then
    if [ "$MAX_ING" -le 200 ] && [ "$MAX_POT" -le 200 ]; then
        pass "Inventory caps: MAX_INGREDIENTS=$MAX_ING, MAX_POTIONS=$MAX_POT (bounded)"
    else
        fail "Inventory caps too high: MAX_INGREDIENTS=$MAX_ING, MAX_POTIONS=$MAX_POT (risk of save bloat)"
    fi
else
    fail "Missing inventory caps in GameState.gd"
fi

#---------------------------------------------------------------------------
# 9. Delete save functionality exists (GDPR right to erasure)
#---------------------------------------------------------------------------
echo "[9] Delete save exists (right to erasure)"

DELETE=$(grep -c "delete_save" "$GODOT_SRC/autoload/SaveManager.gd" 2>/dev/null || true)
DELETE="${DELETE:-0}"

if [ "$DELETE" -gt 0 ]; then
    pass "SaveManager has delete_save() method (right to erasure)"
else
    fail "SaveManager missing delete_save() — GDPR right to erasure not supported"
fi

#---------------------------------------------------------------------------
# 10. Cross-platform ingredient consistency (Roblox ↔ Godot)
#---------------------------------------------------------------------------
echo "[10] Cross-platform ingredient consistency"

# The four original ingredients must exist in both Roblox and Godot
ORIGINALS=("moonpetal" "fireroot" "shadowmoss" "starbloom")

for ing in "${ORIGINALS[@]}"; do
    # Check Godot (lowercase IDs)
    GODOT_HAS=$(grep -c "\"$ing\"" "$GODOT_SRC/autoload/Ingredients.gd" 2>/dev/null || true)
    GODOT_HAS="${GODOT_HAS:-0}"

    # Check Roblox (PascalCase IDs)
    ROBLOX_ID=$(echo "$ing" | sed 's/\b\(.\)/\u\1/g')  # moonpetal -> Moonpetal
    ROBLOX_HAS=$(grep -c "$ROBLOX_ID" "$ROBLOX_SHARED/Ingredients.luau" 2>/dev/null || true)
    ROBLOX_HAS="${ROBLOX_HAS:-0}"

    if [ "$GODOT_HAS" -gt 0 ] && [ "$ROBLOX_HAS" -gt 0 ]; then
        pass "Ingredient '$ing' exists in both Roblox and Godot"
    else
        fail "Ingredient '$ing' missing: Godot=$GODOT_HAS, Roblox=$ROBLOX_HAS"
    fi
done

#---------------------------------------------------------------------------
# 11. Cross-platform rarity multiplier consistency
#---------------------------------------------------------------------------
echo "[11] Rarity multiplier consistency"

# Extract Godot rarity multipliers
GODOT_RARITIES=$(grep -oP '"(Common|Uncommon|Rare|Epic|Legendary)":\s*\K[0-9]+' \
    "$GODOT_SRC/autoload/Recipes.gd" 2>/dev/null || true)

# Extract Roblox multipliers
ROBLOX_RARITIES=$(grep -oP 'multiplier\s*=\s*\K[0-9]+' \
    "$ROBLOX_SHARED/Config.luau" 2>/dev/null || true)

if [ -n "$GODOT_RARITIES" ] && [ -n "$ROBLOX_RARITIES" ]; then
    GODOT_SORTED=$(echo "$GODOT_RARITIES" | sort -n | tr '\n' ',')
    ROBLOX_SORTED=$(echo "$ROBLOX_RARITIES" | sort -n | tr '\n' ',')

    if [ "$GODOT_SORTED" = "$ROBLOX_SORTED" ]; then
        pass "Rarity multipliers match across Roblox and Godot"
    else
        fail "Rarity multiplier mismatch: Godot=[$GODOT_SORTED] vs Roblox=[$ROBLOX_SORTED]"
    fi
else
    warn_ "Could not extract rarity multipliers for comparison"
fi

#---------------------------------------------------------------------------
# 12. Educational content exists (science facts for all ingredients)
#---------------------------------------------------------------------------
echo "[12] Educational content completeness"

# Count ingredients and science facts
ING_COUNT=$(grep -c '"id":' "$GODOT_SRC/autoload/Ingredients.gd" 2>/dev/null || true)
ING_COUNT="${ING_COUNT:-0}"
FACT_COUNT=$(grep -c '"science_fact":' "$GODOT_SRC/autoload/Ingredients.gd" 2>/dev/null || true)
FACT_COUNT="${FACT_COUNT:-0}"

if [ "$ING_COUNT" -gt 0 ] && [ "$ING_COUNT" = "$FACT_COUNT" ]; then
    pass "All $ING_COUNT ingredients have science_fact entries"
else
    fail "Ingredient/science_fact count mismatch: $ING_COUNT ingredients, $FACT_COUNT facts"
fi

#---------------------------------------------------------------------------
# 13. All recipes have science_note (educational content)
#---------------------------------------------------------------------------
echo "[13] Recipe educational content"

RECIPE_COUNT=$(grep -c '"id":' "$GODOT_SRC/autoload/Recipes.gd" 2>/dev/null || true)
RECIPE_COUNT="${RECIPE_COUNT:-0}"
NOTE_COUNT=$(grep -c '"science_note":' "$GODOT_SRC/autoload/Recipes.gd" 2>/dev/null || true)
NOTE_COUNT="${NOTE_COUNT:-0}"

if [ "$RECIPE_COUNT" -gt 0 ] && [ "$RECIPE_COUNT" = "$NOTE_COUNT" ]; then
    pass "All $RECIPE_COUNT recipes have science_note entries"
else
    fail "Recipe/science_note count mismatch: $RECIPE_COUNT recipes, $NOTE_COUNT notes"
fi

#---------------------------------------------------------------------------
# 14. Settings defaults are privacy-protective (UK AADC standard)
#---------------------------------------------------------------------------
echo "[14] Privacy-protective defaults"

# Fullscreen default should be false (don't hijack the screen)
FS_DEFAULT=$(grep -oP '"fullscreen":\s*\K\w+' "$GODOT_SRC/autoload/GameState.gd" 2>/dev/null || true)
if [ "$FS_DEFAULT" = "false" ]; then
    pass "Fullscreen defaults to false (non-intrusive)"
elif [ "$FS_DEFAULT" = "true" ]; then
    warn_ "Fullscreen defaults to true (may be intrusive for young players)"
else
    warn_ "Could not determine fullscreen default"
fi

#---------------------------------------------------------------------------
# 15. No analytics or telemetry in standalone game
#---------------------------------------------------------------------------
echo "[15] No analytics or telemetry"

ANALYTICS=$(grep -rniP '(analytics|telemetry|tracking|metrics|log_event|send_event|report)' \
    "$GODOT_SRC/" 2>/dev/null | grep -v "^\s*##" | grep -v "^\s*#" | grep -v "playtime" || true)

if [ -n "$ANALYTICS" ]; then
    warn_ "Analytics-related terms found (verify these are local-only):"
    echo "$ANALYTICS" | head -3
else
    pass "No analytics or telemetry — fully offline standalone game"
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
