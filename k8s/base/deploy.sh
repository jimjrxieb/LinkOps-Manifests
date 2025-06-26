#!/bin/bash

# LinkOps Kubernetes Deployment Script
# This script deploys all LinkOps microservices to Kubernetes

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
    
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Cannot connect to Kubernetes cluster"
        exit 1
    fi
    
    print_success "kubectl is available and connected to cluster"
}

# Deploy namespace
deploy_namespace() {
    print_status "Creating LinkOps namespace..."
    kubectl apply -f namespace.yaml
    print_success "Namespace created"
}

# Deploy secrets
deploy_secrets() {
    print_status "Creating secrets..."
    kubectl apply -f secrets.yaml
    print_success "Secrets created"
}

# Deploy microservices
deploy_microservices() {
    print_status "Deploying microservices..."
    
    # Deploy James
    print_status "Deploying James..."
    kubectl apply -f james/
    
    # Deploy Whis
    print_status "Deploying Whis..."
    kubectl apply -f whis/
    
    # Deploy Katie
    print_status "Deploying Katie..."
    kubectl apply -f katie/
    
    # Deploy Igris
    print_status "Deploying Igris..."
    kubectl apply -f igris/
    
    print_success "All microservices deployed"
}

# Deploy ingress
deploy_ingress() {
    print_status "Deploying ingress..."
    kubectl apply -f ingress.yaml
    print_success "Ingress deployed"
}

# Wait for deployments
wait_for_deployments() {
    print_status "Waiting for deployments to be ready..."
    
    deployments=("james" "whis" "katie" "igris")
    
    for deployment in "${deployments[@]}"; do
        print_status "Waiting for $deployment deployment..."
        kubectl wait --for=condition=available --timeout=300s deployment/$deployment -n linkops
        print_success "$deployment is ready"
    done
}

# Show status
show_status() {
    print_status "Deployment Status:"
    echo ""
    
    print_status "Pods:"
    kubectl get pods -n linkops
    
    echo ""
    print_status "Services:"
    kubectl get services -n linkops
    
    echo ""
    print_status "Ingress:"
    kubectl get ingress -n linkops
    
    echo ""
    print_success "Deployment completed successfully!"
    print_status "Next steps:"
    echo "1. Update /etc/hosts with ingress IP for local testing"
    echo "2. Access services at:"
    echo "   - James: http://james.linkops.local"
    echo "   - Whis: http://whis.linkops.local"
    echo "   - Katie: http://katie.linkops.local"
    echo "   - Igris: http://igris.linkops.local"
    echo "3. Or use kubectl port-forward for direct access"
}

# Main deployment function
deploy() {
    print_status "Starting LinkOps Kubernetes deployment..."
    echo ""
    
    check_kubectl
    deploy_namespace
    deploy_secrets
    deploy_microservices
    deploy_ingress
    wait_for_deployments
    show_status
}

# Cleanup function
cleanup() {
    print_warning "This will delete all LinkOps resources!"
    read -p "Are you sure you want to proceed? (y/N): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Deleting LinkOps resources..."
        kubectl delete namespace linkops
        print_success "All resources deleted"
    else
        print_warning "Cleanup cancelled"
    fi
}

# Help function
show_help() {
    echo "LinkOps Kubernetes Deployment Script"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  deploy   - Deploy all LinkOps resources (default)"
    echo "  cleanup  - Delete all LinkOps resources"
    echo "  help     - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 deploy"
    echo "  $0 cleanup"
}

# Main script logic
case "${1:-deploy}" in
    deploy)
        deploy
        ;;
    cleanup)
        cleanup
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac 