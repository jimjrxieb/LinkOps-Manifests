# LinkOps Kubernetes Base Configuration

This directory contains the Kubernetes manifests for deploying the LinkOps microservices on AKS.

## Architecture

- **Namespace**: `linkops` - Isolated namespace for all LinkOps resources
- **Microservices**: James, Whis, Katie, Igris - Core LinkOps services
- **Ingress**: NGINX-based ingress controller for external access
- **Secrets**: Centralized secret management for database and API keys

## Directory Structure

```
base/
├── namespace.yaml          # LinkOps namespace
├── secrets.yaml            # Application secrets
├── ingress.yaml            # NGINX ingress configuration
├── kustomization.yaml      # Kustomize configuration
├── deploy.sh              # Deployment script
├── README.md              # This file
├── james/                 # James microservice
│   ├── deployment.yaml
│   └── service.yaml
├── whis/                  # Whis microservice
│   ├── deployment.yaml
│   └── service.yaml
├── katie/                 # Katie microservice
│   ├── deployment.yaml
│   └── service.yaml
├── igris/                 # Igris microservice
│   ├── deployment.yaml
│   └── service.yaml
└── argocd-apps/           # ArgoCD application
    └── linkops-app.yaml
```

## Prerequisites

1. **Kubernetes Cluster**: AKS cluster with NGINX ingress controller
2. **kubectl**: Configured to access your cluster
3. **Container Images**: Built and pushed to ACR
4. **Secrets**: Database URL, API keys, and ACR credentials

## Quick Deployment

### Option 1: Using the deployment script

```bash
cd infrastructure/k8s/base
chmod +x deploy.sh
./deploy.sh deploy
```

### Option 2: Manual deployment

```bash
# Create namespace
kubectl apply -f namespace.yaml

# Create secrets (update with your values first)
kubectl apply -f secrets.yaml

# Deploy microservices
kubectl apply -f james/
kubectl apply -f whis/
kubectl apply -f katie/
kubectl apply -f igris/

# Deploy ingress
kubectl apply -f ingress.yaml

# Wait for deployments
kubectl wait --for=condition=available --timeout=300s deployment/james -n linkops
kubectl wait --for=condition=available --timeout=300s deployment/whis -n linkops
kubectl wait --for=condition=available --timeout=300s deployment/katie -n linkops
kubectl wait --for=condition=available --timeout=300s deployment/igris -n linkops
```

### Option 3: Using Kustomize

```bash
kubectl apply -k .
```

## Configuration

### Environment Variables

Each microservice expects these environment variables:

- `DATABASE_URL`: PostgreSQL connection string
- `OPENAI_API_KEY`: OpenAI API key (James only)
- `KAFKA_BROKERS`: Kafka broker addresses
- `SANITIZER_URL`: Sanitizer service URL (Whis only)
- `FICKNURY_URL`: FickNury service URL (Whis only)

### Resource Limits

- **James**: 256Mi-512Mi RAM, 250m-500m CPU
- **Whis**: 512Mi-1Gi RAM, 500m-1000m CPU
- **Katie**: 256Mi-512Mi RAM, 250m-500m CPU
- **Igris**: 256Mi-512Mi RAM, 250m-500m CPU

### Replicas

- **James**: 2 replicas (high availability)
- **Whis**: 2 replicas (high availability)
- **Katie**: 1 replica
- **Igris**: 1 replica

## Accessing Services

### Via Ingress (External)

After deployment, services are accessible at:

- **James**: `http://james.linkops.local`
- **Whis**: `http://whis.linkops.local`
- **Katie**: `http://katie.linkops.local`
- **Igris**: `http://igris.linkops.local`

### Via kubectl port-forward (Local)

```bash
# James
kubectl port-forward service/james 8080:80 -n linkops

# Whis
kubectl port-forward service/whis 8081:80 -n linkops

# Katie
kubectl port-forward service/katie 8082:80 -n linkops

# Igris
kubectl port-forward service/igris 8083:80 -n linkops
```

### Local Testing Setup

Add these entries to your `/etc/hosts` file:

```bash
# Get the ingress IP
INGRESS_IP=$(kubectl get service -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Add to /etc/hosts (requires sudo)
echo "$INGRESS_IP james.linkops.local whis.linkops.local katie.linkops.local igris.linkops.local linkops.local" | sudo tee -a /etc/hosts
```

## Health Checks

All services include:

- **Liveness Probe**: `/health` endpoint
- **Readiness Probe**: `/ready` endpoint
- **Initial Delay**: 30s for liveness, 5s for readiness
- **Period**: 10s for liveness, 5s for readiness

## Monitoring

### Check Deployment Status

```bash
# All resources
kubectl get all -n linkops

# Pods with details
kubectl get pods -n linkops -o wide

# Services
kubectl get services -n linkops

# Ingress
kubectl get ingress -n linkops
```

### View Logs

```bash
# James logs
kubectl logs -f deployment/james -n linkops

# Whis logs
kubectl logs -f deployment/whis -n linkops

# Katie logs
kubectl logs -f deployment/katie -n linkops

# Igris logs
kubectl logs -f deployment/igris -n linkops
```

### Check Resource Usage

```bash
# Resource usage
kubectl top pods -n linkops

# Node resource usage
kubectl top nodes
```

## Troubleshooting

### Common Issues

1. **Image Pull Errors**: Ensure ACR credentials are correct in secrets
2. **Database Connection**: Verify DATABASE_URL in secrets
3. **Ingress Not Working**: Check NGINX ingress controller is installed
4. **Pods Not Starting**: Check resource limits and requests

### Debug Commands

```bash
# Describe pod for details
kubectl describe pod <pod-name> -n linkops

# Check events
kubectl get events -n linkops --sort-by='.lastTimestamp'

# Check ingress controller
kubectl get pods -n ingress-nginx

# Test service connectivity
kubectl run test-pod --image=busybox --rm -it --restart=Never -- nslookup james
```

## ArgoCD Integration

To deploy via ArgoCD:

1. Update the repository URL in `argocd-apps/linkops-app.yaml`
2. Apply the ArgoCD application:

```bash
kubectl apply -f argocd-apps/linkops-app.yaml
```

## Cleanup

To remove all LinkOps resources:

```bash
# Using script
./deploy.sh cleanup

# Or manually
kubectl delete namespace linkops
```

## Security Notes

- All secrets are stored as Kubernetes secrets
- Services use ClusterIP (internal access only)
- External access is controlled via ingress
- Resource limits prevent resource exhaustion
- Health checks ensure service availability

## Next Steps

1. **Customize Secrets**: Update `secrets.yaml` with your actual values
2. **Build Images**: Build and push microservice images to ACR
3. **Configure Monitoring**: Set up Prometheus/Grafana for monitoring
4. **Set up CI/CD**: Configure automated deployments
5. **Add SSL**: Configure TLS certificates for production 