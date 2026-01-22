#!/usr/bin/env bash
# JSA-DevSec OPA/Rego Linter
# Validates Rego policy syntax and style

set -euo pipefail

POLICY_DIR="${1:-policies}"

echo "=== JSA-DevSec Rego Linter ==="
echo "Policy Directory: $POLICY_DIR"
echo ""

# Find all .rego files
REGO_FILES=$(find "$POLICY_DIR" -name "*.rego" -type f 2>/dev/null || true)

if [ -z "$REGO_FILES" ]; then
    echo "No .rego files found in $POLICY_DIR"
    exit 0
fi

echo "Found $(echo "$REGO_FILES" | wc -l | tr -d ' ') Rego files"
echo ""

# Check syntax
echo "[E-RANK] Checking Rego syntax..."
SYNTAX_ERRORS=0
for file in $REGO_FILES; do
    if ! opa check "$file" 2>/dev/null; then
        echo "  ERROR: $file"
        ((SYNTAX_ERRORS++)) || true
    fi
done

if [ "$SYNTAX_ERRORS" -eq 0 ]; then
    echo "  All files pass syntax check"
else
    echo "  $SYNTAX_ERRORS files with syntax errors"
fi

# Format check (don't auto-fix, just report)
echo ""
echo "[E-RANK] Checking Rego formatting..."
FORMAT_ISSUES=0
for file in $REGO_FILES; do
    FORMATTED=$(opa fmt "$file" 2>/dev/null || cat "$file")
    ORIGINAL=$(cat "$file")
    if [ "$FORMATTED" != "$ORIGINAL" ]; then
        echo "  NEEDS FORMAT: $file"
        ((FORMAT_ISSUES++)) || true
    fi
done

if [ "$FORMAT_ISSUES" -eq 0 ]; then
    echo "  All files properly formatted"
else
    echo "  $FORMAT_ISSUES files need formatting"
fi

# Run conftest verify if available
if command -v conftest &> /dev/null; then
    echo ""
    echo "[D-RANK] Running conftest verify..."
    conftest verify --policy "$POLICY_DIR" 2>/dev/null || true
fi

echo ""
echo "=== Rego lint complete ==="
