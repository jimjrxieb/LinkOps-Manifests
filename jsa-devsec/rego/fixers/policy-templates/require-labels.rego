# JSA-DevSec Policy Template: Require Labels
# Enforces that all Kubernetes resources have required labels
# Defense Rank: D (auto-deployable)

package kubernetes.labels

import rego.v1

# Required labels for all resources
required_labels := {"app.kubernetes.io/name", "app.kubernetes.io/instance"}

# Deny resources missing required labels
deny contains msg if {
	input.kind != "Namespace"
	provided_labels := {label | input.metadata.labels[label]}
	missing_labels := required_labels - provided_labels
	count(missing_labels) > 0
	msg := sprintf("%s/%s is missing required labels: %v", [input.kind, input.metadata.name, missing_labels])
}

# Warn if recommended labels are missing
recommended_labels := {"app.kubernetes.io/version", "app.kubernetes.io/component"}

warn contains msg if {
	input.kind != "Namespace"
	provided_labels := {label | input.metadata.labels[label]}
	missing_recommended := recommended_labels - provided_labels
	count(missing_recommended) > 0
	msg := sprintf("%s/%s is missing recommended labels: %v", [input.kind, input.metadata.name, missing_recommended])
}
