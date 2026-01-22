#!/usr/bin/env bash
# JSA-DevSec YAML Auto-Fixer
# Automatically fixes common YAML issues

set -euo pipefail

TARGET_DIR="${1:-.}"
DRY_RUN="${2:-false}"

echo "=== JSA-DevSec YAML Auto-Fixer ==="
echo "Target: $TARGET_DIR"
echo "Dry Run: $DRY_RUN"
echo ""

# Find YAML files (exclude templates)
YAML_FILES=$(find "$TARGET_DIR" \
    -type f \( -name "*.yaml" -o -name "*.yml" \) \
    -not -path "*/.git/*" \
    -not -path "*/node_modules/*" \
    -not -path "*/vendor/*" \
    -not -path "*/.terraform/*" \
    -not -path "*/templates/*" \
    2>/dev/null || true)

if [ -z "$YAML_FILES" ]; then
    echo "No YAML files found"
    exit 0
fi

FIXED_COUNT=0

for file in $YAML_FILES; do
    NEEDS_FIX=false

    # Check for trailing whitespace
    if grep -q '[[:space:]]$' "$file" 2>/dev/null; then
        NEEDS_FIX=true
        if [ "$DRY_RUN" = "false" ]; then
            sed -i 's/[[:space:]]*$//' "$file"
        fi
    fi

    # Check for missing newline at end
    if [ -n "$(tail -c 1 "$file" 2>/dev/null)" ]; then
        NEEDS_FIX=true
        if [ "$DRY_RUN" = "false" ]; then
            echo "" >> "$file"
        fi
    fi

    # Check for tabs (should be spaces)
    if grep -q $'\t' "$file" 2>/dev/null; then
        NEEDS_FIX=true
        if [ "$DRY_RUN" = "false" ]; then
            sed -i 's/\t/  /g' "$file"
        fi
    fi

    if [ "$NEEDS_FIX" = "true" ]; then
        if [ "$DRY_RUN" = "true" ]; then
            echo "[DRY-RUN] Would fix: $file"
        else
            echo "[FIXED] $file"
        fi
        ((FIXED_COUNT++)) || true
    fi
done

echo ""
echo "Fixed: $FIXED_COUNT files"
echo ""
echo "=== YAML fix complete ==="
