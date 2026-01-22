# AI-START-HERE: Portfolio Deployment Guide

> **For AI Assistants (Cursor, Claude, etc.):** Read this entire file before doing anything.
> Execute steps ONE AT A TIME. Wait for user confirmation between major steps.
> **This guide supports both Windows (PowerShell) and Mac/Linux (Bash).**

---

## What Is This Repo?

This repo (`LinkOps-Manifests`) contains everything needed to deploy the Portfolio application to a Kubernetes cluster. It uses:

- **Helm** = Package manager for Kubernetes (like an app store for servers)
- **ArgoCD** = Auto-deploys changes from GitHub to your cluster
- **CloudFormation** = Creates AWS resources (ECR, Secrets, S3)

---

## Prerequisites Checklist

Before starting, verify these are installed.

### Windows (PowerShell)
```powershell
# Check kubectl
kubectl version --client

# Check helm
helm version

# Check AWS CLI
aws --version

# Check you're connected to your cluster
kubectl get nodes
```

### Mac/Linux (Bash)
```bash
kubectl version --client
helm version
aws --version
kubectl get nodes
```

---

## INSTALLING PREREQUISITES (Windows)

If any tool is missing, install it:

### Option A: Using Chocolatey (Recommended)
```powershell
# Install Chocolatey first (run as Administrator)
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Then install tools
choco install kubernetes-cli -y
choco install kubernetes-helm -y
choco install awscli -y
```

### Option B: Using Winget
```powershell
winget install Kubernetes.kubectl
winget install Helm.Helm
winget install Amazon.AWSCLI
```

### Option C: Manual Downloads
- **kubectl:** https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/
- **helm:** https://helm.sh/docs/intro/install/ (download .zip, extract, add to PATH)
- **aws cli:** https://aws.amazon.com/cli/ (download installer)

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

**What this does:** Creates the AWS resources your app needs.

### Windows (PowerShell)
```powershell
# Navigate to cloudformation folder
cd cloudformation

# Set variables
$env:ENVIRONMENT = "production"
$env:AWS_REGION = "us-east-1"

# Deploy ECR repositories
Write-Host "Deploying ECR repositories..." -ForegroundColor Yellow
aws cloudformation deploy `
  --template-file ecr-repositories.yaml `
  --stack-name portfolio-ecr-production `
  --parameter-overrides Environment=production `
  --capabilities CAPABILITY_IAM `
  --region $env:AWS_REGION

# Deploy Secrets
Write-Host "Deploying Secrets Manager..." -ForegroundColor Yellow
aws cloudformation deploy `
  --template-file secrets.yaml `
  --stack-name portfolio-secrets-production `
  --parameter-overrides Environment=production `
  --capabilities CAPABILITY_NAMED_IAM `
  --region $env:AWS_REGION

# Deploy S3
Write-Host "Deploying S3 bucket..." -ForegroundColor Yellow
aws cloudformation deploy `
  --template-file s3-artifacts.yaml `
  --stack-name portfolio-s3-production `
  --parameter-overrides Environment=production `
  --capabilities CAPABILITY_NAMED_IAM `
  --region $env:AWS_REGION

# Deploy IAM roles
Write-Host "Deploying IAM roles..." -ForegroundColor Yellow
aws cloudformation deploy `
  --template-file iam-roles.yaml `
  --stack-name portfolio-iam-production `
  --parameter-overrides Environment=production `
  --capabilities CAPABILITY_NAMED_IAM `
  --region $env:AWS_REGION

Write-Host "All stacks deployed!" -ForegroundColor Green
```

### Mac/Linux (Bash)
```bash
cd cloudformation/
chmod +x deploy.sh
./deploy.sh production
```

**Expected output:** Each stack should complete without errors.

**If it fails:** Check AWS credentials:
```powershell
# Windows
aws sts get-caller-identity
```
```bash
# Mac/Linux
aws sts get-caller-identity
```

---

## STEP 2: Set Your Secret Values

**What this does:** Puts your actual API keys into AWS Secrets Manager.

### Windows (PowerShell)
```powershell
# Set your Claude API key (REQUIRED)
# REPLACE the placeholder with your real key!
aws secretsmanager put-secret-value `
  --secret-id portfolio/production/claude-api-key `
  --secret-string "sk-ant-api03-YOUR-ACTUAL-KEY-HERE" `
  --region us-east-1

# Set OpenAI key if you have one (OPTIONAL)
aws secretsmanager put-secret-value `
  --secret-id portfolio/production/openai-api-key `
  --secret-string "sk-YOUR-OPENAI-KEY-HERE" `
  --region us-east-1
```

### Mac/Linux (Bash)
```bash
aws secretsmanager put-secret-value \
  --secret-id portfolio/production/claude-api-key \
  --secret-string "sk-ant-api03-YOUR-ACTUAL-KEY-HERE"

aws secretsmanager put-secret-value \
  --secret-id portfolio/production/openai-api-key \
  --secret-string "sk-YOUR-OPENAI-KEY-HERE"
```

**IMPORTANT:** Replace the placeholder text with your real API keys!

---

## STEP 3: Install ArgoCD

**What this does:** Installs the tool that auto-deploys your app.

### Windows (PowerShell)
```powershell
# Go back to repo root
cd ..

# Create the argocd namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready (takes 2-3 minutes)
Write-Host "Waiting for ArgoCD to be ready..." -ForegroundColor Yellow
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# Get the admin password (SAVE THIS!)
Write-Host "ArgoCD Admin Password:" -ForegroundColor Green
$password = kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}"
[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($password))
```

### Mac/Linux (Bash)
```bash
cd ..
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

echo "ArgoCD Admin Password:"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo
```

**Save the password!** You'll need it to access the ArgoCD dashboard.

---

## STEP 4: Deploy the App-of-Apps

**What this does:** Tells ArgoCD to watch this repo and deploy everything.

### Windows (PowerShell)
```powershell
# Deploy the master application
kubectl apply -f argocd\app-of-apps.yaml

# Check that it was created
kubectl get applications -n argocd
```

### Mac/Linux (Bash)
```bash
kubectl apply -f argocd/app-of-apps.yaml
kubectl get applications -n argocd
```

**Expected output:**
```
NAME              SYNC STATUS   HEALTH STATUS
portfolio-root    Synced        Healthy
```

---

## STEP 5: Verify Deployment

**Wait 5-10 minutes**, then check everything is running:

### Windows & Mac/Linux (same commands)
```powershell
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

### ArgoCD Dashboard
```powershell
# Windows & Mac/Linux
kubectl port-forward svc/argocd-server -n argocd 8080:443
```
Then open browser: **https://localhost:8080**
- Username: `admin`
- Password: (from Step 3)

### Grafana Dashboard
```powershell
kubectl port-forward svc/monitoring-grafana -n monitoring 3000:80
```
Then open browser: **http://localhost:3000**
- Username: `admin`
- Password: `prom-operator`

### Your Portfolio App
```powershell
kubectl get ingress -n portfolio
```

---

## TROUBLESHOOTING

### Problem: "kubectl not recognized"
**Windows:** Add kubectl to your PATH or reinstall via Chocolatey.
```powershell
# Check where kubectl is
Get-Command kubectl
```

### Problem: Pods stuck in "Pending"
```powershell
kubectl describe pod <pod-name> -n portfolio
```
Usually means: Not enough CPU/memory on your nodes.

### Problem: Pods in "CrashLoopBackOff"
```powershell
kubectl logs -n portfolio deployment/portfolio-api
```
Usually means: Missing environment variable or secret.

### Problem: Can't connect to cluster
```powershell
# Check your kubeconfig
kubectl config view
kubectl config current-context
```

### Problem: ArgoCD shows "OutOfSync"
```powershell
# Force a sync
kubectl patch app portfolio-app -n argocd --type merge -p '{\"operation\": {\"sync\": {}}}'
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
│   ├── jsa-infrasec.yaml   ← Infrastructure security agent
│   └── policies.yaml       ← OPA security policies
├── cloudformation/          ← AWS infrastructure
│   ├── deploy.sh           ← For Mac/Linux
│   ├── ecr-repositories.yaml
│   ├── secrets.yaml
│   ├── s3-artifacts.yaml
│   └── iam-roles.yaml
├── helm/                    ← Kubernetes "recipes"
│   ├── portfolio-app/      ← Your app's Helm chart
│   │   ├── values.yaml     ← SETTINGS (change image tags here)
│   │   └── templates/      ← Kubernetes manifests
│   ├── monitoring/         ← Prometheus + Grafana Helm chart
│   └── jsa-infrasec/       ← Infrastructure Security Agent
│       ├── values.yaml     ← Agent configuration
│       └── templates/      ← Deployment, RBAC, ServiceMonitor
├── jsa-devsec/              ← DevSecOps tooling
│   ├── terraform/          ← Terraform linters (tfsec, tflint)
│   │   ├── linters/        ← .tfsec.yaml, .tflint.hcl
│   │   └── fixers/         ← auto-fix.sh
│   ├── rego/               ← OPA/Rego policy tools
│   │   ├── linters/        ← conftest.yaml, opa-check.sh
│   │   └── fixers/         ← auto-format.sh, policy-templates/
│   └── yaml/               ← YAML linting tools
│       ├── linters/        ← .yamllint.yaml, lint.sh
│       └── fixers/         ← fix-yaml.sh, k8s-security-fixes.yaml
└── policies/               ← OPA/Gatekeeper security policies
```

---

## UPDATING YOUR APP (After Initial Deploy)

Once everything is deployed, updating is easy:

1. **Change something** in `helm\portfolio-app\values.yaml` (like image tag)
2. **Commit and push** to GitHub
3. **ArgoCD automatically deploys** the change (within 3 minutes)

---

## QUICK COMMAND REFERENCE

| Task | Windows (PowerShell) | Mac/Linux |
|------|---------------------|-----------|
| See all pods | `kubectl get pods -A` | Same |
| See ArgoCD apps | `kubectl get applications -n argocd` | Same |
| Check app logs | `kubectl logs -n portfolio deployment/portfolio-api` | Same |
| Restart deployment | `kubectl rollout restart deployment/portfolio-api -n portfolio` | Same |
| Delete everything | `kubectl delete -f argocd\app-of-apps.yaml` | Use `/` instead of `\` |

---

## WINDOWS-SPECIFIC TIPS

1. **Use PowerShell, not Command Prompt (cmd)**
   - PowerShell is more powerful and supports the commands in this guide

2. **Run as Administrator when installing tools**
   - Right-click PowerShell → "Run as Administrator"

3. **Path separators**
   - Windows uses `\` (backslash)
   - Mac/Linux uses `/` (forward slash)
   - kubectl accepts both, but be consistent

4. **Line continuation**
   - Windows PowerShell uses `` ` `` (backtick)
   - Mac/Linux uses `\` (backslash)

5. **If kubectl is slow on Windows**
   - This is normal the first time
   - It's connecting to your remote cluster

---

## SUMMARY

### Windows (PowerShell)
```powershell
# 1. Deploy AWS infrastructure
cd cloudformation
# (run the CloudFormation commands from Step 1)

# 2. Set secrets
aws secretsmanager put-secret-value --secret-id portfolio/production/claude-api-key --secret-string "YOUR-KEY"

# 3. Install ArgoCD
cd ..
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 4. Deploy everything
kubectl apply -f argocd\app-of-apps.yaml

# 5. Verify
kubectl get pods -n portfolio
```

### Mac/Linux (Bash)
```bash
cd cloudformation && ./deploy.sh production
aws secretsmanager put-secret-value --secret-id portfolio/production/claude-api-key --secret-string "YOUR-KEY"
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl apply -f argocd/app-of-apps.yaml
kubectl get pods -n portfolio
```

**Total time:** About 15-20 minutes for first deployment.

---

*Last updated: January 2026*
*Supports: Windows (PowerShell), Mac, Linux*
