# LinkOps-Manifests

Kubernetes manifests for the LinkOps application stack using GitOps with ArgoCD and Kustomize.

## 🏗️ Structure

```
k8s/
├── base/                    # Base manifests (source of truth)
│   ├── kustomization.yaml   # Main kustomization
│   ├── namespace.yaml       # LinkOps namespace
│   ├── secrets.yaml         # Application secrets
│   ├── postgres-secret.yaml # Database credentials
│   ├── grafana-secret.yaml  # Monitoring credentials
│   ├── ingress.yaml         # Ingress configuration
│   ├── james/               # James microservice
│   ├── whis/                # Whis microservice
│   ├── katie/               # Katie microservice
│   ├── igris/               # Igris microservice
│   ├── frontend/            # Frontend application
│   └── argocd-apps/         # ArgoCD application definitions
│       ├── kustomization.yaml
│       └── linkops-app.yaml # App-of-Apps definition
└── argocd/                  # ArgoCD server configuration
```

## 🚀 GitOps Deployment

### Prerequisites
- ArgoCD installed in your cluster
- Access to the LinkOps-Manifests repository

### Deployment Steps

1. **Apply the App-of-Apps:**
   ```bash
   kubectl apply -k k8s/base/argocd-apps/
   ```

2. **Verify Deployment:**
   ```bash
   kubectl get applications -n argocd
   kubectl get pods -n linkops
   ```

3. **Access Applications:**
   - **Frontend:** `http://linkops.local` (via ingress)
   - **ArgoCD UI:** `http://argocd.local` (if exposed)

## 🧪 Testing

Run the test script to validate manifests:
```bash
./test-kustomize.sh
```

## 🔧 Customization

### Adding a New Service
1. Create service directory in `base/`
2. Add `deployment.yaml`, `service.yaml`, and `kustomization.yaml`
3. Update `base/kustomization.yaml` to include the new service

### Environment-Specific Configurations
Create overlays for different environments:
```
k8s/
├── base/
└── overlays/
    ├── development/
    ├── staging/
    └── production/
```

## 📋 Services

- **James:** Data processing microservice
- **Whis:** AI/ML inference service
- **Katie:** Analytics and reporting service
- **Igris:** Authentication and authorization service
- **Frontend:** React-based web interface

## 🔐 Secrets Management

Secrets are managed through Kubernetes secrets:
- `linkops-secrets`: Application secrets (API keys, etc.)
- `postgres-secret`: Database credentials
- `grafana-secret`: Monitoring credentials

## 📊 Monitoring

- **Prometheus:** Metrics collection
- **Grafana:** Dashboards and visualization
- **AlertManager:** Alerting and notifications

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes to manifests
4. Test with `./test-kustomize.sh`
5. Submit a pull request

## 📄 License

This project is part of the LinkOps platform. 