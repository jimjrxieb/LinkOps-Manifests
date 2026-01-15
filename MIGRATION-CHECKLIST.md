# LinkOps-Manifests → Portfolio-Ready Migration Checklist

> **Goal:** Transform this repo so ArgoCD can monitor it and deploy the Portfolio application to your server.

---

## Current State Summary

| Component | Current | Target |
|-----------|---------|--------|
| App Helm Chart | `helm/linkops-app` | `helm/portfolio-app` |
| Monitoring | Basic stubs only | Full Prometheus + Grafana |
| ArgoCD App | Points to `linkops-app` | Points to `portfolio-app` |
| Infra Provisioning | None | CloudFormation |
| Security | Missing | Security contexts, NetworkPolicies |

---

## Phase 1: Restructure Helm Charts

### 1.1 Rename linkops-app → portfolio-app
- [ ] Rename directory `helm/linkops-app` → `helm/portfolio-app`
- [ ] Update `helm/portfolio-app/Chart.yaml`:
  - [ ] `name: portfolio-app`
  - [ ] `description: Portfolio Application - AI/ML Showcase`
  - [ ] `home: https://github.com/jimjrxieb/Portfolio`
- [ ] Update `helm/portfolio-app/values.yaml`:
  - [ ] Change image repository to `ghcr.io/jimjrxieb/portfolio-api`
  - [ ] Add UI image configuration
  - [ ] Add ChromaDB configuration
  - [ ] Add security contexts
  - [ ] Add resource limits per component

### 1.2 Update portfolio-app Templates
- [ ] Create `templates/_helpers.tpl` (standard Helm helpers)
- [ ] Update `templates/deployment.yaml` → split into:
  - [ ] `templates/deployment-api.yaml`
  - [ ] `templates/deployment-ui.yaml`
  - [ ] `templates/deployment-chroma.yaml`
- [ ] Update `templates/service.yaml` → split for each component
- [ ] Add `templates/ingress.yaml`
- [ ] Add `templates/secret.yaml` (external secret refs)
- [ ] Add `templates/serviceaccount.yaml`
- [ ] Add `templates/networkpolicy.yaml`
- [ ] Add `templates/pvc.yaml` (for ChromaDB persistence)

### 1.3 Add Security Configurations
- [ ] Add `securityContext` to all deployments:
  ```yaml
  securityContext:
    runAsNonRoot: true
    runAsUser: 10001
    fsGroup: 10001
  containerSecurityContext:
    allowPrivilegeEscalation: false
    readOnlyRootFilesystem: true
    capabilities:
      drop: ["ALL"]
  ```
- [ ] Add health probes to all deployments
- [ ] Add resource requests/limits

---

## Phase 2: Monitoring Stack (Prometheus + Grafana)

### 2.1 Option A: Use Helm Dependencies (Recommended)
- [ ] Update `helm/monitoring/Chart.yaml` to use official charts as dependencies:
  ```yaml
  dependencies:
    - name: prometheus
      version: "25.x.x"
      repository: https://prometheus-community.github.io/helm-charts
    - name: grafana
      version: "7.x.x"
      repository: https://grafana.github.io/helm-charts
  ```
- [ ] Run `helm dependency update helm/monitoring/`

### 2.2 Option B: Build Custom (More Control)
- [ ] Create proper Prometheus deployment:
  - [ ] `templates/prometheus-deployment.yaml`
  - [ ] `templates/prometheus-configmap.yaml` (scrape configs)
  - [ ] `templates/prometheus-service.yaml`
  - [ ] `templates/prometheus-pvc.yaml`
- [ ] Create proper Grafana deployment:
  - [ ] `templates/grafana-deployment.yaml`
  - [ ] `templates/grafana-configmap.yaml` (datasources)
  - [ ] `templates/grafana-service.yaml`
  - [ ] `templates/grafana-secret.yaml` (admin password)
- [ ] Add ServiceMonitor for Portfolio app (if using Prometheus Operator)

### 2.3 Update monitoring values.yaml
- [ ] Add Prometheus scrape targets for Portfolio
- [ ] Add Grafana dashboards for Portfolio
- [ ] Configure retention and storage
- [ ] Add alerting rules

---

## Phase 3: ArgoCD Applications

### 3.1 Update Portfolio Application
- [ ] Rename `k8s/argocd/applications/linkops-app.yaml` → `portfolio-app.yaml`
- [ ] Update application spec:
  - [ ] `metadata.name: portfolio-app`
  - [ ] `spec.source.path: helm/portfolio-app`
  - [ ] `spec.destination.namespace: portfolio`
  - [ ] Add sync waves
  - [ ] Add health checks
  - [ ] Add ignoreDifferences for replicas

### 3.2 Update Monitoring Application
- [ ] Update `k8s/argocd/applications/monitoring.yaml`:
  - [ ] Point to `helm/monitoring`
  - [ ] Set `spec.destination.namespace: monitoring`
  - [ ] Add proper sync policy

### 3.3 Create App-of-Apps (Optional but Recommended)
- [ ] Create `k8s/argocd/applications/root-app.yaml`:
  - [ ] Manages all other ArgoCD applications
  - [ ] Single entry point for cluster bootstrap

---

## Phase 4: CloudFormation for AWS Infrastructure

### 4.1 Create CloudFormation Directory
- [ ] Create `cloudformation/` directory structure:
  ```
  cloudformation/
  ├── templates/
  │   ├── vpc.yaml           # VPC, Subnets, IGW
  │   ├── eks-cluster.yaml   # EKS Cluster
  │   ├── eks-nodegroup.yaml # Node Groups
  │   ├── ecr.yaml           # Container Registry
  │   ├── iam-roles.yaml     # IAM Roles for K8s
  │   └── secrets.yaml       # Secrets Manager
  ├── parameters/
  │   ├── dev.json
  │   └── prod.json
  └── deploy.sh              # Deployment script
  ```

### 4.2 Create Core Templates
- [ ] `vpc.yaml`: VPC with public/private subnets
- [ ] `eks-cluster.yaml`: EKS cluster definition
- [ ] `eks-nodegroup.yaml`: Worker node configuration
- [ ] `ecr.yaml`: ECR repositories for Portfolio images
- [ ] `iam-roles.yaml`: IRSA roles for K8s service accounts

### 4.3 Create Parameter Files
- [ ] `parameters/dev.json`: Development environment
- [ ] `parameters/prod.json`: Production environment

---

## Phase 5: Clean Up Old/Unused Files

### 5.1 K8s Base Directory
- [ ] Review `k8s/base/` - determine what's still needed:
  - [ ] `james/`, `whis/`, `katie/`, `igris/` - DELETE if not used
  - [ ] `frontend/` - MIGRATE to helm chart or DELETE
  - [ ] `postgres/` - MIGRATE to helm chart if needed
- [ ] Update `k8s/base/kustomization.yaml` to remove old refs
- [ ] Update or remove `k8s/base/argocd-apps/linkops-app.yaml`

### 5.2 Remove Deprecated Files
- [ ] Review and clean `secrets.yaml`, `grafana-secret.yaml`
- [ ] Update `.github/workflows/ci.yml` for new structure

---

## Phase 6: GitHub Actions / CI Updates

### 6.1 Update CI Workflow
- [ ] Update `.github/workflows/ci.yml`:
  - [ ] Lint new helm charts
  - [ ] Validate CloudFormation templates
  - [ ] Run security scans (Trivy, Checkov)
  - [ ] Test kustomize builds

### 6.2 Add Security Scanning
- [ ] Add Trivy scan for helm charts
- [ ] Add Checkov scan for CloudFormation
- [ ] Add Gitleaks for secrets detection

---

## Phase 7: Documentation

### 7.1 Update README.md
- [ ] Document new structure
- [ ] Add deployment instructions
- [ ] Add ArgoCD setup guide
- [ ] Add CloudFormation deployment guide

### 7.2 Create ARCHITECTURE.md
- [ ] Document component relationships
- [ ] Document ArgoCD sync flow
- [ ] Document monitoring setup

---

## Final Verification Checklist

### Helm Charts
- [ ] `helm lint helm/portfolio-app` passes
- [ ] `helm lint helm/monitoring` passes
- [ ] `helm template helm/portfolio-app` renders correctly
- [ ] `helm template helm/monitoring` renders correctly

### ArgoCD Applications
- [ ] All Application manifests are valid YAML
- [ ] Repo URLs are correct
- [ ] Paths point to correct directories
- [ ] Namespaces are correct

### CloudFormation
- [ ] `aws cloudformation validate-template` passes for all templates
- [ ] Parameters files have all required values

### Security
- [ ] All deployments have security contexts
- [ ] All containers run as non-root
- [ ] Resource limits are defined
- [ ] NetworkPolicies are in place

---

## Quick Start After Migration

```bash
# 1. Deploy CloudFormation (if using AWS)
cd cloudformation && ./deploy.sh dev

# 2. Install ArgoCD on cluster
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 3. Apply root application (ArgoCD will sync everything else)
kubectl apply -f k8s/argocd/applications/root-app.yaml

# 4. Access ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

---

## File Structure After Migration

```
LinkOps-Manifests/
├── .github/
│   └── workflows/
│       └── ci.yml                    # Updated CI
├── helm/
│   ├── portfolio-app/                # RENAMED from linkops-app
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   ├── values-dev.yaml
│   │   ├── values-prod.yaml
│   │   └── templates/
│   │       ├── _helpers.tpl
│   │       ├── deployment-api.yaml
│   │       ├── deployment-ui.yaml
│   │       ├── deployment-chroma.yaml
│   │       ├── service.yaml
│   │       ├── ingress.yaml
│   │       ├── secret.yaml
│   │       ├── serviceaccount.yaml
│   │       ├── networkpolicy.yaml
│   │       └── pvc.yaml
│   └── monitoring/                   # ENHANCED
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
│           ├── prometheus-*.yaml
│           └── grafana-*.yaml
├── k8s/
│   └── argocd/
│       ├── namespace.yaml
│       └── applications/
│           ├── root-app.yaml         # NEW - App of Apps
│           ├── portfolio-app.yaml    # RENAMED
│           └── monitoring.yaml       # UPDATED
├── cloudformation/                   # NEW
│   ├── templates/
│   │   ├── vpc.yaml
│   │   ├── eks-cluster.yaml
│   │   └── ...
│   ├── parameters/
│   │   ├── dev.json
│   │   └── prod.json
│   └── deploy.sh
├── README.md                         # UPDATED
└── ARCHITECTURE.md                   # NEW
```

---

*Created: 2026-01-15*
*Status: Ready to implement*