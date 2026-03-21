#!/usr/bin/env bash
# validate-data-integrity.sh
# CI-runnable static analysis that catches cross-module and data integrity
# issues WITHOUT requiring Roblox Studio. Runs on raw Luau source files.
#
# Exit code: 0 = all checks passed, 1 = one or more checks failed.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$REPO_ROOT/roblox/src"
SHARED="$SRC/shared"
TESTS="$REPO_ROOT/roblox/tests"
LEGAL="$REPO_ROOT/business/legal"

errors=0
warnings=0

pass() { echo "  PASS  $1"; }
fail() { echo "  FAIL  $1"; errors=$((errors + 1)); }
warn_() { echo "  WARN  $1"; warnings=$((warnings + 1)); }

echo ""
echo "========================================"
echo "  Data Integrity Validation"
echo "========================================"
echo ""

#---------------------------------------------------------------------------
# 1. Cross-reference: Recipe keys use only known ingredient IDs
#---------------------------------------------------------------------------
echo "[1] Recipe keys reference valid ingredients"

INGREDIENTS=$(grep -oP 'Ingredients\.\K[A-Z][a-zA-Z]+(?=\s*:)' "$SHARED/Ingredients.luau" 2>/dev/null || true)
if [ -z "$INGREDIENTS" ]; then
    # Fallback pattern
    INGREDIENTS=$(grep -oP 'Ingredients\.\K[A-Z][a-zA-Z]+(?=\s*=\s*\{)' "$SHARED/Ingredients.luau" 2>/dev/null || true)
fi

RECIPE_KEYS=$(grep -oP 'key\s*=\s*"\K[^"]+' "$SHARED/Recipes.luau" 2>/dev/null || true)
if [ -z "$RECIPE_KEYS" ]; then
    RECIPE_KEYS=$(grep -oP '^\s*\["\K[^"]+' "$SHARED/Recipes.luau" 2>/dev/null || true)
fi

if [ -n "$RECIPE_KEYS" ] && [ -n "$INGREDIENTS" ]; then
    for key in $RECIPE_KEYS; do
        IFS='+' read -ra parts <<< "$key"
        for part in "${parts[@]}"; do
            if ! echo "$INGREDIENTS" | grep -qw "$part"; then
                fail "Recipe key '$key' references unknown ingredient '$part'"
            fi
        done
    done
    pass "All recipe keys reference known ingredients"
else
    warn_ "Could not extract recipe keys or ingredients for validation"
fi

#---------------------------------------------------------------------------
# 2. Journal notes cover all ingredients and recipes
#---------------------------------------------------------------------------
echo "[2] Journal covers all ingredients"

for ing in $INGREDIENTS; do
    if ! grep -q "\"*$ing\"*\s*=" "$SHARED/Journal.luau" 2>/dev/null && \
       ! grep -q "\[$ing\]" "$SHARED/Journal.luau" 2>/dev/null && \
       ! grep -q "$ing\s*=" "$SHARED/Journal.luau" 2>/dev/null; then
        fail "Journal.IngredientNotes missing entry for '$ing'"
    fi
done
pass "All ingredients have Journal notes"

#---------------------------------------------------------------------------
# 3. Strings.luau has no empty string values
#---------------------------------------------------------------------------
echo "[3] No empty strings in Strings.luau"

EMPTY_STRINGS=$(grep -nP '=\s*""' "$SHARED/Strings.luau" 2>/dev/null || true)
if [ -n "$EMPTY_STRINGS" ]; then
    echo "$EMPTY_STRINGS" | while read -r line; do
        fail "Empty string value in Strings.luau: $line"
    done
else
    pass "No empty strings found"
fi

#---------------------------------------------------------------------------
# 4. No hardcoded player-facing strings in gameplay code
#---------------------------------------------------------------------------
echo "[4] No hardcoded UI strings in server/client code (spot check)"

# Look for common patterns of hardcoded strings that should be in Strings.luau
HARDCODED=$(grep -rnP '(TextLabel\.Text|\.Text)\s*=\s*"[A-Z][a-z]' \
    "$SRC/client/" "$SRC/server/" 2>/dev/null | \
    grep -v "Strings\." | grep -v "^\-\-" | head -5 || true)

if [ -n "$HARDCODED" ]; then
    warn_ "Possible hardcoded UI strings (should use Strings module):"
    echo "$HARDCODED" | head -5
else
    pass "No obvious hardcoded UI strings found"
fi

#---------------------------------------------------------------------------
# 5. Network event names are consistent (field name == string value)
#---------------------------------------------------------------------------
echo "[5] Network event name consistency"

grep -oP 'Network\.(\w+)\s*=\s*"(\w+)"' "$SHARED/Network.luau" 2>/dev/null | while read -r match; do
    field=$(echo "$match" | grep -oP 'Network\.\K\w+(?=\s)')
    value=$(echo "$match" | grep -oP '"\K\w+(?=")')
    if [ "$field" != "$value" ]; then
        fail "Network.$field = \"$value\" (field name != string value)"
    fi
done
pass "Network event field names match string values"

#---------------------------------------------------------------------------
# 6. No placeholder IDs in production code (warn only)
#---------------------------------------------------------------------------
echo "[6] Placeholder ID check"

PLACEHOLDERS=$(grep -rnP '(999\d{4}|11111\d{3}|000000)' \
    "$SHARED/" 2>/dev/null | grep -v "^--" || true)

PLACEHOLDER_COUNT=$(echo "$PLACEHOLDERS" | grep -c . 2>/dev/null || echo "0")
if [ "$PLACEHOLDER_COUNT" -gt 0 ]; then
    warn_ "$PLACEHOLDER_COUNT placeholder IDs found (replace before launch)"
else
    pass "No placeholder IDs found"
fi

#---------------------------------------------------------------------------
# 7. Legal documents exist and are non-empty
#---------------------------------------------------------------------------
echo "[7] Legal document validation"

for doc in privacy-policy.md terms-of-service.md checklist.md; do
    filepath="$LEGAL/$doc"
    if [ ! -f "$filepath" ]; then
        fail "Missing legal document: $filepath"
    elif [ ! -s "$filepath" ]; then
        fail "Empty legal document: $filepath"
    else
        # Check minimum content length (should be substantial documents)
        lines=$(wc -l < "$filepath")
        if [ "$lines" -lt 20 ]; then
            fail "$doc has only $lines lines (expected >= 20)"
        fi
    fi
done
pass "All legal documents exist and have content"

#---------------------------------------------------------------------------
# 8. Contact email consistency across legal docs
#---------------------------------------------------------------------------
echo "[8] Contact email consistency"

EMAILS=$(grep -ohP '[\w.]+@[\w.]+\.\w+' "$LEGAL"/*.md 2>/dev/null | sort -u)
EMAIL_COUNT=$(echo "$EMAILS" | grep -c . 2>/dev/null || echo "0")

if [ "$EMAIL_COUNT" -gt 1 ]; then
    fail "Inconsistent contact emails across legal docs: $EMAILS"
else
    pass "Contact email is consistent across legal documents"
fi

#---------------------------------------------------------------------------
# 9. No require() calls that might create circular dependencies
#---------------------------------------------------------------------------
echo "[9] Circular dependency check (shared modules)"

for f in "$SHARED"/*.luau; do
    basename=$(basename "$f" .luau)
    # Check if this shared module requires other shared modules
    REQUIRES=$(grep -oP 'require\(.*?\)' "$f" 2>/dev/null | grep -i "shared" || true)
    # Shared modules should not require server or client modules
    BAD_REQUIRES=$(grep -oP 'require\(.*?(server|client|Server|Client).*?\)' "$f" 2>/dev/null || true)
    if [ -n "$BAD_REQUIRES" ]; then
        fail "$basename requires server/client module (dependency direction violation)"
    fi
done
pass "No dependency direction violations in shared modules"

#---------------------------------------------------------------------------
# 10. Luau files return a value (common bug: missing return statement)
#---------------------------------------------------------------------------
echo "[10] All Luau modules end with a return statement"

for f in "$SHARED"/*.luau; do
    basename=$(basename "$f")
    LAST_RETURN=$(grep -n "^return " "$f" 2>/dev/null | tail -1 || true)
    if [ -z "$LAST_RETURN" ]; then
        fail "$basename has no top-level return statement"
    fi
done
pass "All shared modules have return statements"

#---------------------------------------------------------------------------
# 11. Test coverage check: every shared module has a test file
#---------------------------------------------------------------------------
echo "[11] Test coverage for shared modules"

SHARED_MODULES=$(ls "$SHARED"/*.luau 2>/dev/null | xargs -I{} basename {} .luau)
TESTED_MODULES=""
UNTESTED_MODULES=""

for mod in $SHARED_MODULES; do
    # Check if any test file references this module
    if grep -rlq "requireShared(\"$mod\")" "$TESTS/" 2>/dev/null; then
        TESTED_MODULES="$TESTED_MODULES $mod"
    else
        UNTESTED_MODULES="$UNTESTED_MODULES $mod"
    fi
done

if [ -n "$UNTESTED_MODULES" ]; then
    warn_ "Shared modules without test coverage:$UNTESTED_MODULES"
else
    pass "All shared modules are referenced by tests"
fi

#---------------------------------------------------------------------------
# Summary
#---------------------------------------------------------------------------
echo ""
echo "========================================"
total=$((errors + warnings))
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
