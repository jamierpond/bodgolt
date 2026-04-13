#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
BGPREPARE="$REPO_DIR/bgprepare"
EXAMPLES="$REPO_DIR/examples/bgprepare"

PASS=0
FAIL=0

assert_contains() {
    local desc="$1" output="$2" expected="$3"
    if echo "$output" | grep -qF "$expected" 2>/dev/null; then
        echo "  PASS: $desc"
        ((PASS++)) || true
    else
        echo "  FAIL: $desc"
        echo "    expected to contain: $expected"
        ((FAIL++)) || true
    fi
}

assert_not_contains() {
    local desc="$1" output="$2" unexpected="$3"
    if echo "$output" | grep -qF "$unexpected" 2>/dev/null; then
        echo "  FAIL: $desc"
        echo "    should not contain: $unexpected"
        ((FAIL++)) || true
    else
        echo "  PASS: $desc"
        ((PASS++)) || true
    fi
}

# ──────────────────────────────────────
echo "Test 1: Basic include expansion"
out=$("$BGPREPARE" "$EXAMPLES/vec_utils.hpp")
assert_contains "math.hpp inlined" "$out" "inline int square(int x)"
assert_contains "vec_utils body present" "$out" "inline std::vector<int> squares"
assert_not_contains "#ifndef stripped" "$out" "#ifndef VEC_UTILS_HPP"
assert_not_contains "#define stripped" "$out" "#define VEC_UTILS_HPP"
assert_not_contains "#endif stripped" "$out" "#endif"
assert_contains "system include kept" "$out" "#include <vector>"

# ──────────────────────────────────────
echo "Test 2: Nested includes + no double-inclusion"
out=$("$BGPREPARE" "$EXAMPLES/app.hpp")
assert_contains "square fn present" "$out" "inline int square(int x)"
assert_contains "cube fn present" "$out" "inline int cube(int x)"
assert_contains "app body present" "$out" "inline void run()"
assert_not_contains "#pragma once stripped" "$out" "#pragma once"
# math.hpp included via vec_utils.hpp, so direct include should be empty
count=$(echo "$out" | grep -c "inline int square" || true)
if [[ "$count" -eq 1 ]]; then
    echo "  PASS: math.hpp not duplicated"
    ((PASS++))
else
    echo "  FAIL: math.hpp duplicated ($count occurrences of square)"
    ((FAIL++))
fi

# ──────────────────────────────────────
echo "Test 3: Deep nested includes"
out=$("$BGPREPARE" "$EXAMPLES/deep/wrapper.hpp")
assert_contains "nested.hpp inlined" "$out" "inline int double_it"
assert_contains "math.hpp inlined" "$out" "inline int square"
assert_contains "wrapper body present" "$out" "inline int double_square"
assert_not_contains "guard stripped" "$out" "#ifndef WRAPPER_HPP"

# ──────────────────────────────────────
echo "Test 4: --keep-guards preserves guards"
out=$("$BGPREPARE" --keep-guards "$EXAMPLES/vec_utils.hpp")
assert_contains "#ifndef kept" "$out" "#ifndef VEC_UTILS_HPP"
assert_contains "#pragma once kept" "$out" "#pragma once"

# ──────────────────────────────────────
echo "Test 5: -o writes to file"
tmpfile=$(mktemp /tmp/bgprepare-test-XXXXXX.hpp)
"$BGPREPARE" "$EXAMPLES/app.hpp" -o "$tmpfile" 2>/dev/null
assert_contains "output file has content" "$(cat "$tmpfile")" "inline void run()"
rm -f "$tmpfile"

# ──────────────────────────────────────
echo "Test 6: Unresolvable include left with warning"
tmpfile=$(mktemp /tmp/bgprepare-test-XXXXXX.hpp)
cat > "$tmpfile" << 'EOF'
#include "does_not_exist.hpp"
int main() { return 0; }
EOF
out=$("$BGPREPARE" "$tmpfile")
assert_contains "warning comment" "$out" "could not resolve: does_not_exist.hpp"
assert_contains "original include kept" "$out" '#include "does_not_exist.hpp"'
rm -f "$tmpfile"

# ──────────────────────────────────────
echo ""
echo "Results: $PASS passed, $FAIL failed"
if [[ "$FAIL" -gt 0 ]]; then
    exit 1
fi
