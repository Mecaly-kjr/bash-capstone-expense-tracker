#!/usr/bin/env bash

set -euo pipefail

SCRIPT="./depenses.sh"
export DEPENSES_FILE="/tmp/depenses-test-$$.txt"

cleanup() {
    rm -f "$DEPENSES_FILE"
}

trap cleanup EXIT

pass() {
    echo "PASS: $1"
}

fail() {
    echo "FAIL: $1"
    exit 1
}

# Test help
"$SCRIPT" help >/dev/null || fail "Help command"
pass "Help command"

# Test adding expenses
"$SCRIPT" add 1500 Food Lunch >/dev/null
"$SCRIPT" add 500 Transport Taxi >/dev/null
"$SCRIPT" add 1000 Food Dinner >/dev/null
pass "Adding expenses"

# Test listing
output=$("$SCRIPT" list)
[[ "$output" == *"Food"* ]] || fail "List command"
pass "Listing expenses"

# Test total
output=$("$SCRIPT" total)
[[ "$output" == *"3000.00 FCFA"* ]] || fail "Total calculation"
pass "Total calculation"

# Test monthly report
output=$("$SCRIPT" month)
[[ "$output" == *"2500.00"* ]] || fail "Monthly Food total"
[[ "$output" == *"500.00"* ]] || fail "Monthly Transport total"
pass "Monthly report"

# Test deleting
"$SCRIPT" delete 2 >/dev/null
output=$("$SCRIPT" list)
[[ "$output" != *"Taxi"* ]] || fail "Delete command"
pass "Deleting expenses"

# Test invalid amount
if "$SCRIPT" add -100 Food Lunch >/dev/null 2>&1; then
    fail "Invalid amount accepted"
fi
pass "Invalid amount rejected"

# Test invalid ID
if "$SCRIPT" delete 99 >/dev/null 2>&1; then
    fail "Unknown ID accepted"
fi
pass "Unknown ID rejected"

echo
echo "All tests passed successfully!"
