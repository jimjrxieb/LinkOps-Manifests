# CloudFormation Templates for Portfolio Infrastructure

AWS CloudFormation templates for provisioning Portfolio application infrastructure.

## Templates

| Template | Description | Dependencies |
|----------|-------------|--------------|
| `ecr-repositories.yaml` | ECR repositories for container images | None |
| `secrets.yaml` | Secrets Manager secrets | None |
| `s3-artifacts.yaml` | S3 bucket for artifacts/backups | None |
| `iam-roles.yaml` | IAM roles for K8s and CI/CD | secrets, s3-artifacts |

## Deployment Order

Deploy stacks in this order (dependencies must exist first):

```bash
# 1. ECR Repositories
aws cloudformation deploy \
  --template-file ecr-repositories.yaml \
  --stack-name portfolio-ecr-production \
  --parameter-overrides Environment=production \
  --capabilities CAPABILITY_IAM

# 2. Secrets
aws cloudformation deploy \
  --template-file secrets.yaml \
  --stack-name portfolio-secrets-production \
  --parameter-overrides Environment=production \
  --capabilities CAPABILITY_NAMED_IAM

# 3. S3 Artifacts
aws cloudformation deploy \
  --template-file s3-artifacts.yaml \
  --stack-name portfolio-s3-production \
  --parameter-overrides Environment=production \
  --capabilities CAPABILITY_NAMED_IAM

# 4. IAM Roles (depends on secrets and s3)
aws cloudformation deploy \
  --template-file iam-roles.yaml \
  --stack-name portfolio-iam-production \
  --parameter-overrides Environment=production \
  --capabilities CAPABILITY_NAMED_IAM
```

## Setting Secrets

After deploying the secrets stack, set the actual secret values:

```bash
# Claude API Key
aws secretsmanager put-secret-value \
  --secret-id portfolio/production/claude-api-key \
  --secret-string "sk-ant-api03-your-key-here"

# OpenAI API Key (if used)
aws secretsmanager put-secret-value \
  --secret-id portfolio/production/openai-api-key \
  --secret-string "sk-your-openai-key-here"
```

## GitHub Actions OIDC Setup

For GitHub Actions to assume the IAM role, configure OIDC:

1. The IAM role is configured to trust `token.actions.githubusercontent.com`
2. In your GitHub workflow, use:

```yaml
permissions:
  id-token: write
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::ACCOUNT_ID:role/portfolio-production-github-actions
          aws-region: us-east-1
```

## Kubernetes Integration

### Using Secrets in K8s

Create a Kubernetes secret from AWS Secrets Manager:

```bash
# Using External Secrets Operator (recommended)
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: portfolio-api-secrets
  namespace: portfolio
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-secrets-manager
    kind: ClusterSecretStore
  target:
    name: portfolio-api-secrets
  data:
    - secretKey: ANTHROPIC_API_KEY
      remoteRef:
        key: portfolio/production/claude-api-key
```

### Using IAM Role (IRSA)

Annotate your K8s service account:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: portfolio-app
  namespace: portfolio
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT_ID:role/portfolio-production-app-role
```

## Stack Outputs

Check stack outputs after deployment:

```bash
aws cloudformation describe-stacks \
  --stack-name portfolio-ecr-production \
  --query 'Stacks[0].Outputs'
```

## Cleanup

Delete stacks in reverse order:

```bash
aws cloudformation delete-stack --stack-name portfolio-iam-production
aws cloudformation delete-stack --stack-name portfolio-s3-production
aws cloudformation delete-stack --stack-name portfolio-secrets-production
aws cloudformation delete-stack --stack-name portfolio-ecr-production
```

Note: S3 bucket has `DeletionPolicy: Retain` - must be manually deleted.
