# JSA-DevSec Local Tools

> DevSecOps tooling for Terraform, Rego (OPA), and YAML files

This folder contains linters and fixers that jsa-devsec uses for local and CI/CD scanning.

## Structure

```
jsa-devsec/
├── terraform/
│   ├── linters/      # tfsec, tflint configs
│   └── fixers/       # terraform fmt, auto-fix scripts
├── rego/
│   ├── linters/      # opa check, conftest configs
│   └── fixers/       # rego formatter, fix templates
├── yaml/
│   ├── linters/      # yamllint config
│   └── fixers/       # yq transformations, auto-fixes
└── README.md
```

## Usage

### Terraform

```bash
# Lint
tfsec --config-file jsa-devsec/terraform/linters/.tfsec.yaml .

# Fix formatting
terraform fmt -recursive .
```

### Rego

```bash
# Lint policies
opa check jsa-devsec/rego/linters/

# Test policies
conftest verify --policy policies/conftest/
```

### YAML

```bash
# Lint
yamllint -c jsa-devsec/yaml/linters/.yamllint.yaml .

# Fix common issues
./jsa-devsec/yaml/fixers/fix-yaml.sh
```

## Integration with CI

These tools are called by the GitHub Actions workflow in `.github/workflows/ci.yml`.

## Iron Legion Ranks

| Tool | Auto-Fix Level | Rank |
|------|---------------|------|
| terraform fmt | Always | E |
| yamllint | Never (lint only) | E |
| tfsec | Auto-fix safe rules | D |
| conftest | Deploy policies | D |
| Complex rego | Requires review | C |
