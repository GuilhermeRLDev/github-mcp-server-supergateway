{{- define "github-mcp-server.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "github-mcp-server.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := include "github-mcp-server.name" . -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "github-mcp-server.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" -}}
{{- end -}}

{{- define "github-mcp-server.labels" -}}
helm.sh/chart: {{ include "github-mcp-server.chart" . }}
app.kubernetes.io/name: {{ include "github-mcp-server.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "github-mcp-server.selectorLabels" -}}
app.kubernetes.io/name: {{ include "github-mcp-server.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "github-mcp-server.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "github-mcp-server.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{- define "github-mcp-server.secretName" -}}
{{- if .Values.github.existingSecret -}}
{{- .Values.github.existingSecret -}}
{{- else -}}
{{- printf "%s-github-auth" (include "github-mcp-server.fullname" .) -}}
{{- end -}}
{{- end -}}

{{- define "github-mcp-server.validateSecret" -}}
{{- if and (not .Values.github.existingSecret) (not .Values.github.personalAccessToken) -}}
{{- fail "Either github.personalAccessToken or github.existingSecret must be set" -}}
{{- end -}}
{{- end -}}

{{- define "github-mcp-server.authSecretName" -}}
{{- if .Values.auth.existingSecret -}}
{{- .Values.auth.existingSecret -}}
{{- else -}}
{{- printf "%s-mcp-auth" (include "github-mcp-server.fullname" .) -}}
{{- end -}}
{{- end -}}

{{- define "github-mcp-server.validateAuth" -}}
{{- if .Values.auth.enabled -}}
{{- if and (not .Values.auth.existingSecret) (not .Values.auth.token) -}}
{{- fail "When auth.enabled=true, either auth.token or auth.existingSecret must be set" -}}
{{- end -}}
{{- end -}}
{{- end -}}
