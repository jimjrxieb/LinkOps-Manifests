{{/*
Expand the name of the chart.
*/}}
{{- define "jsa-infrasec.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "jsa-infrasec.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "jsa-infrasec.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "jsa-infrasec.labels" -}}
helm.sh/chart: {{ include "jsa-infrasec.chart" . }}
{{ include "jsa-infrasec.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: linkops-manifests
{{- end }}

{{/*
Selector labels
*/}}
{{- define "jsa-infrasec.selectorLabels" -}}
app.kubernetes.io/name: {{ include "jsa-infrasec.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: infrastructure-security
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "jsa-infrasec.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "jsa-infrasec.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Full image reference
*/}}
{{- define "jsa-infrasec.image" -}}
{{- $repo := .Values.image.repository }}
{{- $tag := .Values.image.tag | default .Chart.AppVersion }}
{{- printf "%s:%s" $repo $tag }}
{{- end }}
