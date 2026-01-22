# TFLint Configuration for JSA-DevSec
# Terraform linter for best practices

config {
  # Enable all available plugins
  call_module_type = "all"
  force = false
  disabled_by_default = false
}

# AWS Plugin
plugin "aws" {
  enabled = true
  version = "0.31.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

# Terraform Plugin (built-in rules)
plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

# Naming conventions
rule "terraform_naming_convention" {
  enabled = true
  format  = "snake_case"
}

# Require version constraints
rule "terraform_required_version" {
  enabled = true
}

rule "terraform_required_providers" {
  enabled = true
}

# Documentation
rule "terraform_documented_variables" {
  enabled = true
}

rule "terraform_documented_outputs" {
  enabled = true
}

# Best practices
rule "terraform_unused_declarations" {
  enabled = true
}

rule "terraform_typed_variables" {
  enabled = true
}

# AWS-specific rules (security)
rule "aws_instance_invalid_type" {
  enabled = true
}

rule "aws_db_instance_invalid_type" {
  enabled = true
}

# Disable overly strict rules
rule "terraform_comment_syntax" {
  enabled = false
}
