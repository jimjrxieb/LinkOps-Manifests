# Portfolio Infrastructure Manifests

Kubernetes manifests and infrastructure-as-code for the Portfolio application using GitOps with ArgoCD and Helm.

## Structure

```
LinkOps-Manifests/
├── argocd/                     # ArgoCD Applications
│   ├── app-of-apps.yaml        # Root application (deploy first)
│   ├── portfolio-app.yaml      # Main Portfolio application
│   ├── monitoring.yaml         # Prometheus/Grafana stack
│   ├── policies.yaml           # OPA Gatekeeper policies
│   └── README.md
├── cloudformation/             # AWS CloudFormation templates
│   ├── ecr-repositories.yaml   # Container registries
│   ├── secrets.yaml            # Secrets Manager secrets
│   ├── s3-artifacts.yaml       # Artifacts bucket
│   ├── iam-roles.yaml          # IAM roles for K8s/CI
│   ├── deploy.sh               # Deployment script
│   └── README.md
├── helm/                       # Helm Charts
│   ├── portfolio-app/          # Main application chart
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   └── templates/
│   │       ├── deployment-api.yaml
│   │       ├── deployment-ui.yaml
│   │       ├── deployment-chroma.yaml
│   │       ├── service.yaml
│   │       ├── ingress.yaml
│   │       ├── networkpolicy.yaml
│   │       └── ...
│   └── monitoring/             # Monitoring stack chart
│       ├── Chart.yaml          # Uses kube-prometheus-stack
│       ├── values.yaml
│       └── templates/
│           ├── servicemonitor-portfolio.yaml
│           ├── prometheus-rules-portfolio.yaml
│           └── grafana-dashboard-portfolio.yaml
├── policies/                   # Security Policies
│   ├── gatekeeper/             # OPA Gatekeeper
│   │   ├── constraint-templates.yaml
│   │   └── constraints.yaml
│   ├── conftest/               # CI Policy Checks
│   │   ├── kubernetes.rego
│   │   └── helm.rego
│   └── README.md
└── .github/workflows/          # CI/CD
    └── ci.yml
```

## Quick Start

### 1. Deploy AWS Infrastructure (if using AWS)

```bash
cd cloudformation/
./deploy.sh production
```

### 2. Deploy ArgoCD Applications

```bash
# Install ArgoCD (if not installed)
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Deploy App-of-Apps
kubectl apply -f argocd/app-of-apps.yaml
```

### 3. Verify Deployment

```bash
# Check ArgoCD applications
kubectl get applications -n argocd

# Check Portfolio pods
kubectl get pods -n portfolio

# Check monitoring
kubectl get pods -n monitoring
```

## Components

### Portfolio Application

| Component | Description | Port |
|-----------|-------------|------|
| API | FastAPI backend with RAG | 8000 |
| UI | React frontend | 8080 |
| ChromaDB | Vector database | 8000 |

### Monitoring Stack

- **Prometheus**: Metrics collection and alerting rules
- **Grafana**: Dashboards and visualization
- **Alertmanager**: Alert routing and notifications

### Security Policies

- **Gatekeeper**: Admission control policies
- **Conftest**: CI/CD policy validation
- **PSS**: Pod Security Standards (restricted)

## Security Features

All workloads are configured with:
- `runAsNonRoot: true`
- `allowPrivilegeEscalation: false`
- `readOnlyRootFilesystem: true`
- `capabilities.drop: [ALL]`
- Resource limits and requests
- Network policies
- Pod Security Standards (restricted)

## Local Development

### Validate Helm Charts

```bash
# Lint charts
helm lint helm/portfolio-app/
helm lint helm/monitoring/

# Render templates
helm template portfolio-app helm/portfolio-app/

# Test with policies
helm template portfolio-app helm/portfolio-app/ | conftest test - --policy policies/conftest/
```

### Validate CloudFormation

```bash
aws cloudformation validate-template --template-body file://cloudformation/ecr-repositories.yaml
```

## ArgoCD Access

```bash
# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Port forward
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

## CI/CD Pipeline

The CI pipeline validates:
1. YAML syntax (yamllint)
2. Helm chart structure (helm lint)
3. OPA policies (conftest)
4. Security scanning (Trivy)
5. CloudFormation templates

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes
4. Ensure CI passes
5. Submit a pull request

## License

MIT License - See LICENSE file
