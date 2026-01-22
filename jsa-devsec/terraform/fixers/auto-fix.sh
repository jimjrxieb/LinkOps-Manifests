#!/usr/bin/env bash
# JSA-DevSec Terraform Auto-Fixer
# Applies safe, automated fixes to Terraform code

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${1:-.}"

echo "=== JSA-DevSec Terraform Auto-Fixer ==="
echo "Target: $PROJECT_ROOT"
echo ""

# E-rank fixes (always safe)
echo "[E-RANK] Running terraform fmt..."
terraform fmt -recursive "$PROJECT_ROOT" 2>/dev/null || true

# Check if tfsec is available
if command -v tfsec &> /dev/null; then
    echo "[D-RANK] Running tfsec scan..."
    tfsec "$PROJECT_ROOT" \
        --config-file "$SCRIPT_DIR/../linters/.tfsec.yaml" \
        --format json \
        --out /tmp/tfsec-results.json || true

    # Count findings by severity
    if [ -f /tmp/tfsec-results.json ]; then
        CRITICAL=$(jq '[.results[] | select(.severity == "CRITICAL")] | length' /tmp/tfsec-results.json 2>/dev/null || echo "0")
        HIGH=$(jq '[.results[] | select(.severity == "HIGH")] | length' /tmp/tfsec-results.json 2>/dev/null || echo "0")
        MEDIUM=$(jq '[.results[] | select(.severity == "MEDIUM")] | length' /tmp/tfsec-results.json 2>/dev/null || echo "0")
        LOW=$(jq '[.results[] | select(.severity == "LOW")] | length' /tmp/tfsec-results.json 2>/dev/null || echo "0")

        echo ""
        echo "TFSec Results:"
        echo "  CRITICAL: $CRITICAL"
        echo "  HIGH:     $HIGH"
        echo "  MEDIUM:   $MEDIUM"
        echo "  LOW:      $LOW"
    fi
fi

# Check if tflint is available
if command -v tflint &> /dev/null; then
    echo ""
    echo "[E-RANK] Running tflint..."
    cd "$PROJECT_ROOT"
    tflint --init --config="$SCRIPT_DIR/../linters/.tflint.hcl" 2>/dev/null || true
    tflint --config="$SCRIPT_DIR/../linters/.tflint.hcl" || true
    cd - > /dev/null
fi

echo ""
echo "=== Auto-fix complete ==="
