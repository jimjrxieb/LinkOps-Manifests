# Conftest Policies for Helm Values Validation
# Run: conftest test helm/portfolio-app/values.yaml --policy policies/conftest/
# Validates Helm values before template rendering

package main

# Deny if security context not configured
deny[msg] {
    input.api.securityContext == null
    msg := "API component must have securityContext configured"
}

deny[msg] {
    input.ui.securityContext == null
    msg := "UI component must have securityContext configured"
}

# Deny if runAsNonRoot not set in security context
deny[msg] {
    input.api.securityContext.runAsNonRoot != true
    msg := "API securityContext.runAsNonRoot must be true"
}

deny[msg] {
    input.ui.securityContext.runAsNonRoot != true
    msg := "UI securityContext.runAsNonRoot must be true"
}

# Deny if resource limits not configured
deny[msg] {
    not input.api.resources.limits
    msg := "API must have resource limits configured"
}

deny[msg] {
    not input.ui.resources.limits
    msg := "UI must have resource limits configured"
}

# Warn if network policy disabled
warn[msg] {
    input.networkPolicy.enabled != true
    msg := "NetworkPolicy should be enabled for production"
}

# Deny if service account auto-mount not explicitly set
warn[msg] {
    input.serviceAccount.automountServiceAccountToken != false
    msg := "ServiceAccount should set automountServiceAccountToken=false unless needed"
}

# Deny if ingress enabled without TLS
warn[msg] {
    input.ingress.enabled == true
    input.ingress.tls.enabled != true
    msg := "Ingress should use TLS in production"
}

# Warn if replica count is 1 (no HA)
warn[msg] {
    input.api.replicaCount == 1
    msg := "API replicaCount=1 provides no high availability"
}

warn[msg] {
    input.ui.replicaCount == 1
    msg := "UI replicaCount=1 provides no high availability"
}
