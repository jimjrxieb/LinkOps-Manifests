# JSA-DevSec Policy Template: Require Security Context
# Enforces security context on all containers
# Defense Rank: D (auto-deployable)

package kubernetes.security

import rego.v1

# Deny containers running as root
deny contains msg if {
	container := input_containers[_]
	not container.securityContext.runAsNonRoot
	msg := sprintf("Container %s must set securityContext.runAsNonRoot: true", [container.name])
}

# Deny privileged containers
deny contains msg if {
	container := input_containers[_]
	container.securityContext.privileged == true
	msg := sprintf("Container %s must not run in privileged mode", [container.name])
}

# Deny containers without capability drops
deny contains msg if {
	container := input_containers[_]
	not container.securityContext.capabilities.drop
	msg := sprintf("Container %s must drop all capabilities", [container.name])
}

# Warn if read-only root filesystem is not set
warn contains msg if {
	container := input_containers[_]
	not container.securityContext.readOnlyRootFilesystem
	msg := sprintf("Container %s should set readOnlyRootFilesystem: true", [container.name])
}

# Helper to get all containers
input_containers contains container if {
	container := input.spec.containers[_]
}

input_containers contains container if {
	container := input.spec.initContainers[_]
}

input_containers contains container if {
	container := input.spec.template.spec.containers[_]
}

input_containers contains container if {
	container := input.spec.template.spec.initContainers[_]
}
