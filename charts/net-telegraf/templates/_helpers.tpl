{{/*
Expand the name of the chart.
*/}}
{{- define "net-telegraf.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "net-telegraf.fullname" -}}
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
{{- define "net-telegraf.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "net-telegraf.labels" -}}
helm.sh/chart: {{ include "net-telegraf.chart" . }}
{{ include "net-telegraf.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "net-telegraf.selectorLabels" -}}
app.kubernetes.io/name: {{ include "net-telegraf.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Generate extra volumes for custom scripts
*/}}
{{- define "net-telegraf.customScriptsVolume" -}}
{{- if .Values.customScripts.enabled }}
- name: custom-scripts
  configMap:
    name: {{ include "net-telegraf.fullname" . }}-scripts
    defaultMode: 0755
{{- end }}
{{- end }}

{{/*
Generate extra volume mounts for custom scripts
*/}}
{{- define "net-telegraf.customScriptsVolumeMount" -}}
{{- if .Values.customScripts.enabled }}
- name: custom-scripts
  mountPath: {{ .Values.customScripts.mountPath }}
  readOnly: true
{{- end }}
{{- end }}

