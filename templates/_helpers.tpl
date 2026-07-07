{{/*
M1 naming/labels — R2.

Every rendered resource derives its name and labels through these helpers so
naming and labelling stay consistent across the whole chart (Deployment,
Service, ServiceAccount, ConfigMap, PVC, and whatever the
networking-operational-addons task adds on top).
*/}}

{{/*
Chart name, honoring nameOverride.
*/}}
{{- define "generic-app-chart.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Fully qualified resource name. Honors fullnameOverride first; otherwise
combines the release name with the (possibly overridden) chart name, avoiding
duplication when the release name already contains it.
*/}}
{{- define "generic-app-chart.fullname" -}}
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
"<chart-name>-<chart-version>", used for the helm.sh/chart label.
*/}}
{{- define "generic-app-chart.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Standard Helm common labels, merged with .Values.commonLabels (R39) so every
resource that renders through this shared helper picks up commonLabels
automatically, without each template bolting the merge on individually.
Chart-managed keys (helm.sh/chart, the selector labels, version, managed-by)
always win on conflict — letting commonLabels override
app.kubernetes.io/name/instance would break the selectors that depend on them
elsewhere in the chart.
*/}}
{{- define "generic-app-chart.labels" -}}
{{- $selector := include "generic-app-chart.selectorLabels" . | fromYaml -}}
{{- $managed := merge $selector (dict "helm.sh/chart" (include "generic-app-chart.chart" .) "app.kubernetes.io/version" .Chart.AppVersion "app.kubernetes.io/managed-by" .Release.Service) -}}
{{- $common := .Values.commonLabels | default dict -}}
{{- mergeOverwrite (deepCopy $common) $managed | toYaml -}}
{{- end }}

{{/*
Stable selector labels — must never change across releases/upgrades, so they
are deliberately narrower than the full label set (name + instance only).
*/}}
{{- define "generic-app-chart.selectorLabels" -}}
app.kubernetes.io/name: {{ include "generic-app-chart.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Name of the ServiceAccount the Deployment runs as (R14). When
serviceAccount.create is true (default), this is the dedicated SA this chart
creates — named after the fullname unless overridden. When false, it
references an existing SA the caller already created.
*/}}
{{- define "generic-app-chart.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "generic-app-chart.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
