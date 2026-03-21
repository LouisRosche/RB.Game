#!/usr/bin/env bash
# validate-launch-readiness.sh
# CI-runnable script that tracks audit-identified gaps and launch blockers.
# Prevents regression by failing if previously-resolved items break again.
#
# Categories:
#   HARD BLOCKER — must be resolved before any launch; CI fails if broken
#   SOFT BLOCKER — must be resolved before public launch; CI warns
#   TRACKED      — operational items; CI warns as reminder
#
# Exit code: 0 = no hard blockers, 1 = hard blockers detected.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$REPO_ROOT/roblox/src"
SHARED="$SRC/shared"
SERVER="$SRC/server"
LEGAL="$REPO_ROOT/business/legal"
GODOT="$REPO_ROOT/godot"

errors=0
warnings=0

pass() { echo "  PASS  $1"; }
fail() { echo "  FAIL  $1"; errors=$((errors + 1)); }
warn_() { echo "  WARN  $1"; warnings=$((warnings + 1)); }
info() { echo "  INFO  $1"; }

echo ""
echo "========================================"
echo "  Launch Readiness Tracker"
echo "========================================"
echo ""

echo "--- HARD BLOCKERS (CI fails if broken) ---"
echo ""

#---------------------------------------------------------------------------
# H1. Privacy policy exists and has minimum content
#---------------------------------------------------------------------------
echo "[H1] Privacy policy"
PP="$LEGAL/privacy-policy.md"
if [ -f "$PP" ]; then
    PP_LINES=$(wc -l < "$PP")
    if [ "$PP_LINES" -ge 50 ]; then
        pass "Privacy policy exists ($PP_LINES lines)"
    else
        fail "Privacy policy too short ($PP_LINES lines, expected >= 50)"
    fi
else
    fail "Privacy policy missing"
fi

#---------------------------------------------------------------------------
# H2. Terms of service exists and has minimum content
#---------------------------------------------------------------------------
echo "[H2] Terms of service"
TOS="$LEGAL/terms-of-service.md"
if [ -f "$TOS" ]; then
    TOS_LINES=$(wc -l < "$TOS")
    if [ "$TOS_LINES" -ge 50 ]; then
        pass "Terms of service exists ($TOS_LINES lines)"
    else
        fail "Terms of service too short ($TOS_LINES lines, expected >= 50)"
    fi
else
    fail "Terms of service missing"
fi

#---------------------------------------------------------------------------
# H3. Legal checklist exists
#---------------------------------------------------------------------------
echo "[H3] Legal checklist"
CL="$LEGAL/checklist.md"
if [ -f "$CL" ]; then
    CL_LINES=$(wc -l < "$CL")
    if [ "$CL_LINES" -ge 30 ]; then
        pass "Legal checklist exists ($CL_LINES lines)"
    else
        fail "Legal checklist too short ($CL_LINES lines, expected >= 30)"
    fi
else
    fail "Legal checklist missing"
fi

#---------------------------------------------------------------------------
# H4. CI pipeline exists and has compliance job
#---------------------------------------------------------------------------
echo "[H4] CI pipeline with compliance"
CI="$REPO_ROOT/.github/workflows/ci.yml"
if [ -f "$CI" ]; then
    HAS_COMPLIANCE=$(grep -c "compliance:" "$CI" 2>/dev/null || true)
    HAS_COMPLIANCE="${HAS_COMPLIANCE:-0}"
    if [ "$HAS_COMPLIANCE" -gt 0 ]; then
        pass "CI pipeline includes compliance job"
    else
        fail "CI pipeline missing compliance job"
    fi
else
    fail "CI pipeline file missing"
fi

#---------------------------------------------------------------------------
# H5. ProfileService integration (not stub)
#---------------------------------------------------------------------------
echo "[H5] ProfileService integration"
DS="$SERVER/Services/DataService.luau"
if [ -f "$DS" ]; then
    HAS_PROFILE=$(grep -c "ProfileService" "$DS" 2>/dev/null || true)
    HAS_PROFILE="${HAS_PROFILE:-0}"
    HAS_SESSION=$(grep -c "ListenToRelease" "$DS" 2>/dev/null || true)
    HAS_SESSION="${HAS_SESSION:-0}"
    if [ "$HAS_PROFILE" -gt 0 ] && [ "$HAS_SESSION" -gt 0 ]; then
        pass "DataService uses ProfileService with session locking"
    else
        fail "DataService missing ProfileService or session locking"
    fi
else
    fail "DataService.luau not found"
fi

#---------------------------------------------------------------------------
# H6. Refund notice in shop UI (CARU requirement)
#---------------------------------------------------------------------------
echo "[H6] Refund notice in shop UI"
REFUND_STRING=$(grep -c "REFUND_NOTICE" "$SHARED/Strings.luau" 2>/dev/null || true)
REFUND_STRING="${REFUND_STRING:-0}"
REFUND_UI=$(grep -rc "REFUND_NOTICE\|RefundNotice" "$SRC/client/" 2>/dev/null | \
    awk -F: '{s+=$NF} END {print s+0}' || echo "0")

if [ "$REFUND_STRING" -gt 0 ] && [ "$REFUND_UI" -gt 0 ]; then
    pass "Refund notice string exists and is displayed in shop UI"
elif [ "$REFUND_STRING" -gt 0 ]; then
    warn_ "Refund notice string exists but may not be displayed in UI"
else
    fail "Refund notice missing from Strings.luau (CARU requirement)"
fi

#---------------------------------------------------------------------------
# H7. Godot scenes exist for standalone game
#---------------------------------------------------------------------------
echo "[H7] Godot scenes exist"
SCENE_COUNT=$(find "$GODOT" -name "*.tscn" 2>/dev/null | wc -l || echo "0")
if [ "$SCENE_COUNT" -ge 3 ]; then
    pass "Godot has $SCENE_COUNT scene files"
else
    fail "Godot needs at least 3 scenes, found $SCENE_COUNT"
fi

echo ""
echo "--- SOFT BLOCKERS (warnings, pre-public-launch) ---"
echo ""

#---------------------------------------------------------------------------
# S1. Placeholder ID count (warn, track trend)
#---------------------------------------------------------------------------
echo "[S1] Placeholder IDs"
PLACEHOLDER_COUNT=$(grep -rnP '(999\d{4}|11111\d{3}|000000|PLACEHOLDER|REPLACE_ME)' \
    "$SHARED/" 2>/dev/null | grep -v "^\s*--" | wc -l || echo "0")

if [ "$PLACEHOLDER_COUNT" -eq 0 ]; then
    pass "No placeholder IDs — ready for launch"
else
    warn_ "$PLACEHOLDER_COUNT placeholder IDs remaining (replace before launch)"
fi

#---------------------------------------------------------------------------
# S2. Audio asset placeholders
#---------------------------------------------------------------------------
echo "[S2] Audio asset IDs"
AUDIO_MD="$REPO_ROOT/roblox/AUDIO_ASSETS.md"
if [ -f "$AUDIO_MD" ]; then
    AUDIO_PLACEHOLDER=$(grep -cP '(TBD|TODO|000000|placeholder)' "$AUDIO_MD" 2>/dev/null || true)
    AUDIO_PLACEHOLDER="${AUDIO_PLACEHOLDER:-0}"
    if [ "$AUDIO_PLACEHOLDER" -gt 0 ]; then
        warn_ "$AUDIO_PLACEHOLDER audio asset(s) still need IDs"
    else
        pass "All audio asset IDs populated"
    fi
else
    warn_ "AUDIO_ASSETS.md not found (audio asset tracking file)"
fi

#---------------------------------------------------------------------------
# S3. Hardcoded UI strings (should use Strings module)
#---------------------------------------------------------------------------
echo "[S3] Hardcoded UI strings"
HARDCODED=$(grep -rnP '(\.Text)\s*=\s*"[A-Z][a-z]' \
    "$SRC/client/" "$SRC/server/" 2>/dev/null | \
    grep -v "Strings\." | grep -v "^\s*--" | wc -l || echo "0")

if [ "$HARDCODED" -eq 0 ]; then
    pass "No hardcoded UI strings"
else
    warn_ "$HARDCODED potential hardcoded UI string(s) — should use Strings module"
fi

#---------------------------------------------------------------------------
# S4. Contact email set and valid
#---------------------------------------------------------------------------
echo "[S4] Contact email"
EMAIL=$(grep -ohP '[\w.]+@[\w.]+\.\w+' "$LEGAL"/*.md 2>/dev/null | head -1 || true)
if [ -n "$EMAIL" ]; then
    if echo "$EMAIL" | grep -qP '@(example|placeholder|todo)'; then
        warn_ "Contact email appears to be a placeholder: $EMAIL"
    else
        pass "Contact email set: $EMAIL"
    fi
else
    warn_ "No contact email found in legal documents"
fi

echo ""
echo "--- TRACKED ITEMS (informational) ---"
echo ""

#---------------------------------------------------------------------------
# T1. LLC formation status
#---------------------------------------------------------------------------
echo "[T1] LLC formation"
if grep -qi "filed\|registered\|completed\|done" "$CL" 2>/dev/null | grep -qi "LLC" 2>/dev/null; then
    info "LLC formation may be completed (verify manually)"
else
    info "LLC formation pending (checklist item)"
fi

#---------------------------------------------------------------------------
# T2. Trademark search status
#---------------------------------------------------------------------------
echo "[T2] Trademark"
TM="$REPO_ROOT/docs/trademark-domain-research.md"
if [ -f "$TM" ]; then
    info "Trademark research document exists — verify filing status manually"
else
    info "Trademark research document not found"
fi

#---------------------------------------------------------------------------
# T3. Test module coverage
#---------------------------------------------------------------------------
echo "[T3] Test module coverage"
SHARED_COUNT=$(ls "$SHARED"/*.luau 2>/dev/null | wc -l || echo "0")
TESTED=$(ls "$REPO_ROOT/roblox/tests/"*Tests.luau 2>/dev/null | wc -l || echo "0")
info "$TESTED test modules covering $SHARED_COUNT shared modules"

#---------------------------------------------------------------------------
# Summary
#---------------------------------------------------------------------------
echo ""
echo "========================================"
if [ "$errors" -eq 0 ]; then
    if [ "$warnings" -gt 0 ]; then
        echo "  LAUNCH READY (hard blockers clear, $warnings soft warnings)"
    else
        echo "  LAUNCH READY (all clear)"
    fi
    echo "========================================"
    exit 0
else
    echo "  NOT READY: $errors hard blocker(s)  |  $warnings soft warning(s)"
    echo "========================================"
    exit 1
fi
