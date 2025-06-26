#!/bin/bash

# LinkOps Kustomize Test Script
# This script validates and optionally applies Kustomize manifests

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if kubectl is available
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed or not in PATH"
        exit 1
    fi
}

# Check if kustomize is available
check_kustomize() {
    if ! command -v kustomize &> /dev/null; then
        print_warning "kustomize is not installed, using kubectl kustomize instead"
        KUSTOMIZE_CMD="kubectl kustomize"
    else
        KUSTOMIZE_CMD="kustomize build"
    fi
}

# Validate manifests
validate_manifests() {
    print_status "Validating Kustomize manifests..."
    
    # Test base kustomization
    print_status "Testing base kustomization..."
    if $KUSTOMIZE_CMD k8s/base/ > /dev/null; then
        print_success "Base kustomization is valid"
    else
        print_error "Base kustomization validation failed"
        exit 1
    fi
    
    # Test individual services
    services=("james" "whis" "katie" "igris" "frontend" "postgres")
    for service in "${services[@]}"; do
        print_status "Testing $service service..."
        if $KUSTOMIZE_CMD k8s/base/$service/ > /dev/null; then
            print_success "$service kustomization is valid"
        else
            print_error "$service kustomization validation failed"
            exit 1
        fi
    done
    
    # Test ArgoCD apps
    print_status "Testing ArgoCD apps..."
    if $KUSTOMIZE_CMD k8s/base/argocd-apps/ > /dev/null; then
        print_success "ArgoCD apps kustomization is valid"
    else
        print_error "ArgoCD apps kustomization validation failed"
        exit 1
    fi
}

# Dry run apply
dry_run_apply() {
    print_status "Performing dry-run apply..."
    
    if kubectl apply -k k8s/base/ --dry-run=client; then
        print_success "Dry-run apply successful"
    else
        print_error "Dry-run apply failed"
        exit 1
    fi
}

# Show generated manifests
show_manifests() {
    print_status "Generated manifests:"
    echo "========================"
    $KUSTOMIZE_CMD k8s/base/
}

# Main script
main() {
    echo "🧪 LinkOps Kustomize Test Script"
    echo "================================"
    echo
    
    check_kubectl
    check_kustomize
    
    case "${1:-validate}" in
        "validate")
            validate_manifests
            print_success "All manifests are valid!"
            ;;
        "dry-run")
            validate_manifests
            dry_run_apply
            print_success "Dry-run completed successfully!"
            ;;
        "show")
            show_manifests
            ;;
        "apply")
            print_warning "This will apply manifests to your cluster!"
            read -p "Are you sure? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                validate_manifests
                print_status "Applying manifests to cluster..."
                kubectl apply -k k8s/base/
                print_success "Manifests applied successfully!"
            else
                print_status "Apply cancelled"
            fi
            ;;
        *)
            echo "Usage: $0 [validate|dry-run|show|apply]"
            echo "  validate: Validate all kustomizations (default)"
            echo "  dry-run:  Perform dry-run apply"
            echo "  show:     Show generated manifests"
            echo "  apply:    Apply manifests to cluster"
            exit 1
            ;;
    esac
}

main "$@" 