#!/usr/bin/env bash
# JSA-DevSec Rego Auto-Formatter
# Automatically formats Rego files to standard style

set -euo pipefail

POLICY_DIR="${1:-policies}"
DRY_RUN="${2:-false}"

echo "=== JSA-DevSec Rego Auto-Formatter ==="
echo "Policy Directory: $POLICY_DIR"
echo "Dry Run: $DRY_RUN"
echo ""

# Find all .rego files
REGO_FILES=$(find "$POLICY_DIR" -name "*.rego" -type f 2>/dev/null || true)

if [ -z "$REGO_FILES" ]; then
    echo "No .rego files found"
    exit 0
fi

FORMATTED_COUNT=0
UNCHANGED_COUNT=0

for file in $REGO_FILES; do
    ORIGINAL=$(cat "$file")
    FORMATTED=$(opa fmt "$file" 2>/dev/null || echo "$ORIGINAL")

    if [ "$FORMATTED" != "$ORIGINAL" ]; then
        if [ "$DRY_RUN" = "true" ]; then
            echo "[DRY-RUN] Would format: $file"
        else
            echo "$FORMATTED" > "$file"
            echo "[FORMATTED] $file"
        fi
        ((FORMATTED_COUNT++)) || true
    else
        ((UNCHANGED_COUNT++)) || true
    fi
done

echo ""
echo "Summary:"
echo "  Formatted: $FORMATTED_COUNT"
echo "  Unchanged: $UNCHANGED_COUNT"
echo ""
echo "=== Rego format complete ==="
