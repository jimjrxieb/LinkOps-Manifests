# Conftest Policies for Portfolio App Kubernetes Manifests
# Run: conftest test helm/portfolio-app/templates/ --policy policies/conftest/
# Policy-First: Shift-left security validation before deployment

package main

import future.keywords.in

# Deny privileged containers
deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    container.securityContext.privileged == true
    msg := sprintf("CRITICAL: Container '%s' in Deployment '%s' runs as privileged", [container.name, input.metadata.name])
}

# Deny containers running as root
deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not container.securityContext.runAsNonRoot
    not input.spec.template.spec.securityContext.runAsNonRoot
    msg := sprintf("CRITICAL: Container '%s' in Deployment '%s' must set runAsNonRoot=true", [container.name, input.metadata.name])
}

# Deny containers with allowPrivilegeEscalation
deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    container.securityContext.allowPrivilegeEscalation != false
    msg := sprintf("HIGH: Container '%s' in Deployment '%s' must set allowPrivilegeEscalation=false", [container.name, input.metadata.name])
}

# Require dropping ALL capabilities
deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not "ALL" in container.securityContext.capabilities.drop
    msg := sprintf("HIGH: Container '%s' in Deployment '%s' must drop ALL capabilities", [container.name, input.metadata.name])
}

# Require resource limits
deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not container.resources.limits.memory
    msg := sprintf("MEDIUM: Container '%s' in Deployment '%s' missing memory limits", [container.name, input.metadata.name])
}

deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not container.resources.limits.cpu
    msg := sprintf("MEDIUM: Container '%s' in Deployment '%s' missing CPU limits", [container.name, input.metadata.name])
}

# Require resource requests
deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not container.resources.requests.memory
    msg := sprintf("MEDIUM: Container '%s' in Deployment '%s' missing memory requests", [container.name, input.metadata.name])
}

deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not container.resources.requests.cpu
    msg := sprintf("MEDIUM: Container '%s' in Deployment '%s' missing CPU requests", [container.name, input.metadata.name])
}

# Require readOnlyRootFilesystem
deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not container.securityContext.readOnlyRootFilesystem
    msg := sprintf("MEDIUM: Container '%s' in Deployment '%s' should use readOnlyRootFilesystem=true", [container.name, input.metadata.name])
}

# Require liveness probe
warn[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not container.livenessProbe
    msg := sprintf("LOW: Container '%s' in Deployment '%s' missing livenessProbe", [container.name, input.metadata.name])
}

# Require readiness probe
warn[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not container.readinessProbe
    msg := sprintf("LOW: Container '%s' in Deployment '%s' missing readinessProbe", [container.name, input.metadata.name])
}

# Deny hostPath volumes
deny[msg] {
    input.kind == "Deployment"
    volume := input.spec.template.spec.volumes[_]
    volume.hostPath
    msg := sprintf("CRITICAL: Deployment '%s' uses hostPath volume '%s' - forbidden", [input.metadata.name, volume.name])
}

# Deny hostNetwork
deny[msg] {
    input.kind == "Deployment"
    input.spec.template.spec.hostNetwork == true
    msg := sprintf("CRITICAL: Deployment '%s' uses hostNetwork - forbidden", [input.metadata.name])
}

# Deny hostPID
deny[msg] {
    input.kind == "Deployment"
    input.spec.template.spec.hostPID == true
    msg := sprintf("CRITICAL: Deployment '%s' uses hostPID - forbidden", [input.metadata.name])
}

# Deny hostIPC
deny[msg] {
    input.kind == "Deployment"
    input.spec.template.spec.hostIPC == true
    msg := sprintf("CRITICAL: Deployment '%s' uses hostIPC - forbidden", [input.metadata.name])
}

# Require automountServiceAccountToken=false (unless needed)
warn[msg] {
    input.kind == "Deployment"
    input.spec.template.spec.automountServiceAccountToken != false
    msg := sprintf("LOW: Deployment '%s' should set automountServiceAccountToken=false if SA token not needed", [input.metadata.name])
}

# Deny latest tag
deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    endswith(container.image, ":latest")
    msg := sprintf("MEDIUM: Container '%s' in Deployment '%s' uses :latest tag - use specific version", [container.name, input.metadata.name])
}

# Deny images without tags (implies latest)
deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not contains(container.image, ":")
    not contains(container.image, "@sha256:")
    msg := sprintf("MEDIUM: Container '%s' in Deployment '%s' image has no tag - use specific version", [container.name, input.metadata.name])
}

# Require labels
deny[msg] {
    input.kind == "Deployment"
    not input.metadata.labels["app.kubernetes.io/name"]
    msg := sprintf("LOW: Deployment '%s' missing label app.kubernetes.io/name", [input.metadata.name])
}

# Namespace must have PSS labels
deny[msg] {
    input.kind == "Namespace"
    not input.metadata.labels["pod-security.kubernetes.io/enforce"]
    msg := sprintf("HIGH: Namespace '%s' missing Pod Security Standard enforce label", [input.metadata.name])
}

# NetworkPolicy must exist (at application level - just warn)
warn[msg] {
    input.kind == "Deployment"
    msg := "INFO: Ensure NetworkPolicy exists for this deployment"
}
