{{/*
Expand the name of the chart.
*/}}
{{- define "portfolio.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "portfolio.fullname" -}}
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
{{- define "portfolio.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "portfolio.labels" -}}
helm.sh/chart: {{ include "portfolio.chart" . }}
{{ include "portfolio.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "portfolio.selectorLabels" -}}
app.kubernetes.io/name: {{ include "portfolio.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
API selector labels
*/}}
{{- define "portfolio.api.selectorLabels" -}}
{{ include "portfolio.selectorLabels" . }}
app.kubernetes.io/component: api
{{- end }}

{{/*
UI selector labels
*/}}
{{- define "portfolio.ui.selectorLabels" -}}
{{ include "portfolio.selectorLabels" . }}
app.kubernetes.io/component: ui
{{- end }}

{{/*
ChromaDB selector labels
*/}}
{{- define "portfolio.chroma.selectorLabels" -}}
{{ include "portfolio.selectorLabels" . }}
app.kubernetes.io/component: chroma
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "portfolio.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "portfolio.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
