# ArgoCD Applications

This directory contains ArgoCD Application manifests for the Portfolio infrastructure.

## Deployment Order (Sync Waves)

| Wave | Application | Description |
|------|-------------|-------------|
| 0 | portfolio-gatekeeper-templates | OPA ConstraintTemplates |
| 1 | portfolio-gatekeeper-constraints | OPA Constraints |
| 1 | monitoring | Prometheus + Grafana stack |
| 2 | portfolio-app | Main Portfolio application |

## Quick Start

### 1. Install ArgoCD (if not installed)

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### 2. Deploy App-of-Apps

```bash
kubectl apply -f argocd/app-of-apps.yaml
```

This will automatically deploy all other applications in the correct order using sync waves.

### 3. Access ArgoCD UI

```bash
# Get initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Port forward to access UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

## Application Structure

```
argocd/
├── app-of-apps.yaml          # Root application (deploy first)
├── namespace.yaml            # ArgoCD namespace with PSS labels
├── policies.yaml             # Gatekeeper policies applications
├── monitoring.yaml           # Prometheus/Grafana stack
└── portfolio-app.yaml        # Main Portfolio application
```

## Customization

### Using Different Environments

Create environment-specific value files:

```bash
# Production
helm/portfolio-app/values-production.yaml

# Then update argocd/portfolio-app.yaml:
spec:
  source:
    helm:
      valueFiles:
        - values.yaml
        - values-production.yaml
```

### Adding New Applications

1. Create the application YAML in this directory
2. Set the appropriate `argocd.argoproj.io/sync-wave` annotation
3. The App-of-Apps will automatically pick it up

## Troubleshooting

```bash
# Check application sync status
argocd app list

# Sync a specific application
argocd app sync portfolio-app

# Check application health
argocd app get portfolio-app

# View application logs
argocd app logs portfolio-app
```
