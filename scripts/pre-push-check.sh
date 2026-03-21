#!/usr/bin/env bash
# pre-push-check.sh
# Local pre-push validation hook. Runs fast checks before pushing to catch
# compliance regressions and common mistakes without waiting for CI.
#
# INSTALL (optional — symlink into .git/hooks):
#   ln -sf ../../scripts/pre-push-check.sh .git/hooks/pre-push
#
# Or run manually:
#   bash scripts/pre-push-check.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$REPO_ROOT/roblox/src"
SHARED="$SRC/shared"
GODOT_SRC="$REPO_ROOT/godot/src"

errors=0

pass() { echo "  ✓  $1"; }
fail() { echo "  ✗  $1"; errors=$((errors + 1)); }

echo ""
echo "  Pre-push validation"
echo "  ─────────────────────"
echo ""

#---------------------------------------------------------------------------
# 1. No secrets in staged/committed files
#---------------------------------------------------------------------------
SECRETS=$(git ls-files '*.env' '.env.*' 'credentials*' '*.pem' '*.key' '*.p12' 2>/dev/null || true)
if [ -n "$SECRETS" ]; then
    fail "Potential secrets tracked: $SECRETS"
else
    pass "No secrets in tracked files"
fi

#---------------------------------------------------------------------------
# 2. No binary blobs committed
#---------------------------------------------------------------------------
BINARIES=$(git ls-files '*.rbxl' '*.rbxlx' '*.exe' '*.dll' '*.so' '*.dylib' 2>/dev/null || true)
if [ -n "$BINARIES" ]; then
    fail "Binary files committed: $BINARIES"
else
    pass "No binary blobs"
fi

#---------------------------------------------------------------------------
# 3. Legal documents intact
#---------------------------------------------------------------------------
for doc in business/legal/privacy-policy.md business/legal/terms-of-service.md business/legal/checklist.md LICENSE; do
    if [ -f "$REPO_ROOT/$doc" ]; then
        LINES=$(wc -l < "$REPO_ROOT/$doc")
        if [ "$LINES" -lt 10 ]; then
            fail "$doc suspiciously short ($LINES lines)"
        else
            pass "$doc exists ($LINES lines)"
        fi
    else
        fail "$doc missing"
    fi
done

#---------------------------------------------------------------------------
# 4. Shared Luau modules all return a value
#---------------------------------------------------------------------------
MISSING_RETURN=0
for f in "$SHARED"/*.luau; do
    if [ ! -f "$f" ]; then continue; fi
    if ! grep -q "^return " "$f" 2>/dev/null; then
        fail "$(basename "$f") missing return statement"
        MISSING_RETURN=$((MISSING_RETURN + 1))
    fi
done
if [ "$MISSING_RETURN" -eq 0 ]; then
    pass "All shared modules have return statements"
fi

#---------------------------------------------------------------------------
# 5. No new PII fields introduced
#---------------------------------------------------------------------------
PII_ROBLOX=$(grep -rniP '(\.email|\.phone|\.address|\.firstName|\.lastName|\.birthday|\.deviceId|\.ipAddress)' \
    "$SRC/" 2>/dev/null | grep -v "^\s*--" | grep -v "Tests" || true)
PII_GODOT=$(grep -rniP '(email|phone|address|first_name|last_name|birthday|device_id|ip_address)' \
    "$GODOT_SRC/" 2>/dev/null | grep -v "^\s*##" | grep -v "^\s*#" || true)

if [ -n "$PII_ROBLOX" ] || [ -n "$PII_GODOT" ]; then
    fail "PII field detected in source code"
    echo "$PII_ROBLOX" "$PII_GODOT" | head -3
else
    pass "No PII fields in source"
fi

#---------------------------------------------------------------------------
# 6. Mutation odds sum to 1.0 (quick sanity check)
#---------------------------------------------------------------------------
CHANCES=$(grep -oP 'chance\s*=\s*\K[0-9.]+' "$SHARED/Config.luau" 2>/dev/null || true)
if [ -n "$CHANCES" ]; then
    SUM=$(echo "$CHANCES" | awk '{s+=$1} END {printf "%.4f", s}')
    DIFF=$(echo "$SUM" | awk '{d = $1 - 1.0; if (d < 0) d = -d; print d}')
    if awk "BEGIN{exit !($DIFF < 0.001)}" 2>/dev/null; then
        pass "Mutation odds sum to $SUM"
    else
        fail "Mutation odds sum to $SUM (expected 1.0)"
    fi
fi

#---------------------------------------------------------------------------
# 7. No external HTTP requests
#---------------------------------------------------------------------------
HTTP_ROBLOX=$(grep -rniP 'HttpService:?(Get|Post|Request)' "$SRC/" 2>/dev/null | grep -v "^\s*--" || true)
HTTP_GODOT=$(grep -rniP '(HTTPRequest|HTTPClient)' "$GODOT_SRC/" 2>/dev/null | grep -v "^\s*##" || true)

if [ -n "$HTTP_ROBLOX" ] || [ -n "$HTTP_GODOT" ]; then
    fail "External HTTP request found in game code"
else
    pass "No external HTTP requests"
fi

#---------------------------------------------------------------------------
# Summary
#---------------------------------------------------------------------------
echo ""
if [ "$errors" -eq 0 ]; then
    echo "  All checks passed — safe to push."
    echo ""
    exit 0
else
    echo "  $errors check(s) failed — fix before pushing."
    echo ""
    exit 1
fi
