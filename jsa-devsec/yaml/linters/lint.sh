#!/usr/bin/env bash
# JSA-DevSec YAML Linter
# Validates YAML files for syntax and style

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${1:-.}"

echo "=== JSA-DevSec YAML Linter ==="
echo "Target: $TARGET_DIR"
echo ""

# Find YAML files (exclude templates, node_modules, vendor)
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

FILE_COUNT=$(echo "$YAML_FILES" | wc -l | tr -d ' ')
echo "Found $FILE_COUNT YAML files"
echo ""

# Run yamllint if available
if command -v yamllint &> /dev/null; then
    echo "[E-RANK] Running yamllint..."
    yamllint -c "$SCRIPT_DIR/.yamllint.yaml" $YAML_FILES 2>&1 || true
else
    echo "yamllint not installed, skipping..."
fi

# Run yq validation if available
if command -v yq &> /dev/null; then
    echo ""
    echo "[E-RANK] Validating YAML syntax with yq..."
    SYNTAX_ERRORS=0
    for file in $YAML_FILES; do
        if ! yq eval '.' "$file" > /dev/null 2>&1; then
            echo "  SYNTAX ERROR: $file"
            ((SYNTAX_ERRORS++)) || true
        fi
    done

    if [ "$SYNTAX_ERRORS" -eq 0 ]; then
        echo "  All $FILE_COUNT files have valid syntax"
    else
        echo "  $SYNTAX_ERRORS files with syntax errors"
    fi
fi

echo ""
echo "=== YAML lint complete ==="
