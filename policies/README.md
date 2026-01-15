# Portfolio App Security Policies

> "If it can be a policy, make it a policy FIRST" - Constant's Rule

This directory contains OPA-based security policies for the Portfolio application.

## Policy Stack

```
┌─────────────────────────────────────────────────────────┐
│  CI/CD (Shift-Left)                                     │
│  └── Conftest validates manifests BEFORE merge          │
├─────────────────────────────────────────────────────────┤
│  Admission (Gatekeeper)                                 │
│  └── Blocks non-compliant workloads at deploy time      │
├─────────────────────────────────────────────────────────┤
│  Runtime (Namespace PSS)                                │
│  └── Enforces Pod Security Standards                    │
└─────────────────────────────────────────────────────────┘
```

## Quick Start

### CI/CD Validation (Conftest)

```bash
# Install conftest
brew install conftest  # or download from GitHub

# Validate Helm templates
helm template portfolio helm/portfolio-app/ | conftest test - --policy policies/conftest/

# Validate values.yaml
conftest test helm/portfolio-app/values.yaml --policy policies/conftest/
```

### Cluster Admission (Gatekeeper)

```bash
# Install Gatekeeper (if not present)
kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/release-3.14/deploy/gatekeeper.yaml

# Deploy constraint templates first
kubectl apply -f policies/gatekeeper/constraint-templates.yaml

# Wait for templates to be ready
kubectl get constrainttemplates

# Deploy constraints
kubectl apply -f policies/gatekeeper/constraints.yaml
```

## Policy Coverage

| Policy | Severity | What it Enforces |
|--------|----------|------------------|
| No Privileged | CRITICAL | Containers cannot run privileged |
| Run As Non-Root | CRITICAL | Containers must run as non-root user |
| No Privilege Escalation | HIGH | allowPrivilegeEscalation must be false |
| Drop Capabilities | HIGH | Must drop ALL capabilities |
| Resource Limits | MEDIUM | CPU and memory limits required |
| Read-Only Rootfs | MEDIUM | Root filesystem must be read-only |
| Required Probes | LOW | Liveness and readiness probes required |
| Required Labels | LOW | Standard K8s labels required |
| Allowed Repos | MEDIUM | Images must come from approved registries |

## Customization

### Adding Allowed Registries

Edit `policies/gatekeeper/constraints.yaml`:

```yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sAllowedRepos
metadata:
  name: portfolio-allowed-repos
spec:
  parameters:
    repos:
      - "YOUR-ECR-ACCOUNT.dkr.ecr.REGION.amazonaws.com/"
      - "ghcr.io/YOUR-ORG/"
```

### Excluding Namespaces

Add to the constraint's `match` section:

```yaml
spec:
  match:
    excludedNamespaces:
      - "kube-system"
      - "gatekeeper-system"
```

## Troubleshooting

### Pod blocked by Gatekeeper

```bash
# Check violations
kubectl get constraints -o yaml | grep -A20 violations

# Check specific constraint
kubectl describe k8spsprunasnonroot portfolio-run-as-nonroot
```

### Conftest failures in CI

```bash
# Show detailed output
conftest test manifest.yaml --policy policies/conftest/ -o table

# Skip specific rules (not recommended)
conftest test manifest.yaml --policy policies/conftest/ --ignore "Container.*missing.*Probe"
```

## ArgoCD Integration

These policies are deployed via ArgoCD Application. See `argocd/policies.yaml`.

The deployment order is:
1. ConstraintTemplates (must be ready before constraints)
2. Constraints (reference the templates)

ArgoCD sync waves handle this ordering automatically.
