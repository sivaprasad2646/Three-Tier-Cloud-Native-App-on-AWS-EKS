{{/*
Expand the name of the chart
*/}}
{{- define "taskmanager.name" -}}
{{- .Chart.Name -}}
{{- end }}

{{/*
Common labels
*/}}
{{- define "taskmanager.labels" -}}
app.kubernetes.io/name: {{ include "taskmanager.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
environment: {{ .Values.environment }}
{{- end }}