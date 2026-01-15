# AI-START-HERE: Portfolio Deployment Guide

> **For AI Assistants (Cursor, Claude, etc.):** Read this entire file before doing anything.
> Execute steps ONE AT A TIME. Wait for user confirmation between major steps.

---

## What Is This Repo?

This repo (`LinkOps-Manifests`) contains everything needed to deploy the Portfolio application to a Kubernetes cluster. It uses:

- **Helm** = Package manager for Kubernetes (like apt-get for servers)
- **ArgoCD** = Auto-deploys changes from GitHub to your cluster
- **CloudFormation** = Creates AWS resources (ECR, Secrets, S3)

---

## Prerequisites Checklist

Before starting, verify these are installed. Run each command:

```bash
# Check kubectl (talks to Kubernetes)
kubectl version --client

# Check helm (package manager)
helm version

# Check AWS CLI (talks to AWS)
aws --version

# Check you're connected to your cluster
kubectl get nodes
```

**If any command fails, stop and install that tool first.**

---

## DEPLOYMENT ORDER (CRITICAL!)

```
STEP 1: AWS CloudFormation  →  Creates ECR, Secrets, S3, IAM
STEP 2: Set Secret Values   →  Put your API keys in AWS
STEP 3: Install ArgoCD      →  The auto-deployer tool
STEP 4: Deploy App-of-Apps  →  Kicks off everything else
STEP 5: Verify              →  Make sure it worked
```

---

## STEP 1: Deploy AWS Infrastructure

**What this does:** Creates the AWS resources your app needs (container registry, secrets storage, etc.)

```bash
# Navigate to cloudformation folder
cd cloudformation/

# Make the script executable
chmod +x deploy.sh

# Run the deployment (takes 5-10 minutes)
./deploy.sh production
```

**Expected output:** You should see green checkmarks for each stack:
- portfolio-ecr-production ✓
- portfolio-secrets-production ✓
- portfolio-s3-production ✓
- portfolio-iam-production ✓

**If it fails:** Check that your AWS credentials are configured:
```bash
aws sts get-caller-identity
```

---

## STEP 2: Set Your Secret Values

**What this does:** Puts your actual API keys into AWS Secrets Manager.

```bash
# Set your Claude API key (REQUIRED)
aws secretsmanager put-secret-value \
  --secret-id portfolio/production/claude-api-key \
  --secret-string "sk-ant-api03-YOUR-ACTUAL-KEY-HERE"

# Set OpenAI key if you have one (OPTIONAL)
aws secretsmanager put-secret-value \
  --secret-id portfolio/production/openai-api-key \
  --secret-string "sk-YOUR-OPENAI-KEY-HERE"
```

**IMPORTANT:** Replace the placeholder text with your real API keys!

---

## STEP 3: Install ArgoCD

**What this does:** Installs the tool that auto-deploys your app when you push to GitHub.

```bash
# Go back to repo root
cd ..

# Create the argocd namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready (takes 2-3 minutes)
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# Get the admin password (SAVE THIS!)
echo "ArgoCD Admin Password:"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo
```

**Save the password!** You'll need it to access the ArgoCD dashboard.

---

## STEP 4: Deploy the App-of-Apps

**What this does:** Tells ArgoCD to watch this repo and deploy everything.

```bash
# Deploy the master application
kubectl apply -f argocd/app-of-apps.yaml

# Check that it was created
kubectl get applications -n argocd
```

**Expected output:**
```
NAME              SYNC STATUS   HEALTH STATUS
portfolio-root    Synced        Healthy
```

ArgoCD will now automatically deploy:
1. OPA Gatekeeper policies (security)
2. Monitoring stack (Prometheus + Grafana)
3. Portfolio application (API + UI + ChromaDB)

---

## STEP 5: Verify Deployment

**Wait 5-10 minutes**, then check everything is running:

```bash
# Check ArgoCD applications
kubectl get applications -n argocd

# Check portfolio pods
kubectl get pods -n portfolio

# Check monitoring pods
kubectl get pods -n monitoring
```

**All pods should show "Running" status.**

---

## STEP 6: Access Your Apps

### ArgoCD Dashboard (see deployments)
```bash
# Start port forward
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Open browser: https://localhost:8080
# Username: admin
# Password: (from Step 3)
```

### Grafana Dashboard (see metrics)
```bash
# Start port forward
kubectl port-forward svc/monitoring-grafana -n monitoring 3000:80

# Open browser: http://localhost:3000
# Username: admin
# Password: prom-operator (default)
```

### Your Portfolio App
```bash
# Check what IP/hostname was assigned
kubectl get ingress -n portfolio
```

---

## TROUBLESHOOTING

### Problem: Pods stuck in "Pending"
```bash
# Check what's wrong
kubectl describe pod <pod-name> -n portfolio
```
Usually means: Not enough CPU/memory on your nodes.

### Problem: Pods in "CrashLoopBackOff"
```bash
# Check the logs
kubectl logs -n portfolio deployment/portfolio-api
```
Usually means: Missing environment variable or secret.

### Problem: ArgoCD shows "OutOfSync"
```bash
# Force a sync
kubectl patch app portfolio-app -n argocd --type merge -p '{"operation": {"sync": {}}}'
```

### Problem: Can't pull images from ECR
```bash
# Make sure you're logged into ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com
```

---

## FILE STRUCTURE REFERENCE

```
LinkOps-Manifests/
├── AI-START-HERE.md        ← YOU ARE HERE
├── argocd/                  ← ArgoCD application definitions
│   ├── app-of-apps.yaml    ← Deploy this to start everything
│   ├── portfolio-app.yaml  ← Your main app
│   ├── monitoring.yaml     ← Prometheus + Grafana
│   └── policies.yaml       ← OPA security policies
├── cloudformation/          ← AWS infrastructure
│   ├── deploy.sh           ← Run this first!
│   ├── ecr-repositories.yaml
│   ├── secrets.yaml
│   ├── s3-artifacts.yaml
│   └── iam-roles.yaml
├── helm/                    ← Kubernetes "recipes"
│   ├── portfolio-app/      ← Your app's Helm chart
│   │   ├── values.yaml     ← SETTINGS (change image tags here)
│   │   └── templates/      ← Kubernetes manifests
│   └── monitoring/         ← Monitoring Helm chart
└── policies/               ← OPA/Gatekeeper security policies
```

---

## UPDATING YOUR APP (After Initial Deploy)

Once everything is deployed, updating is easy:

1. **Change something** in `helm/portfolio-app/values.yaml` (like image tag)
2. **Commit and push** to GitHub
3. **ArgoCD automatically deploys** the change (within 3 minutes)

That's it! No manual kubectl commands needed.

---

## QUICK COMMAND REFERENCE

| Task | Command |
|------|---------|
| See all pods | `kubectl get pods -A` |
| See ArgoCD apps | `kubectl get applications -n argocd` |
| Check app logs | `kubectl logs -n portfolio deployment/portfolio-api` |
| Force ArgoCD sync | `kubectl patch app portfolio-app -n argocd --type merge -p '{"operation": {"sync": {}}}'` |
| Restart a deployment | `kubectl rollout restart deployment/portfolio-api -n portfolio` |
| Delete everything | `kubectl delete -f argocd/app-of-apps.yaml` |

---

## SUMMARY

```
1. cd cloudformation && ./deploy.sh production     # Create AWS stuff
2. aws secretsmanager put-secret-value ...         # Set your API keys
3. kubectl apply -n argocd -f <argocd-install>     # Install ArgoCD
4. kubectl apply -f argocd/app-of-apps.yaml        # Deploy everything
5. kubectl get pods -n portfolio                    # Verify it works
```

**Total time:** About 15-20 minutes for first deployment.

---

*Last updated: January 2026*
