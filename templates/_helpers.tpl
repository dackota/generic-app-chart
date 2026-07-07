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
Standard Helm common labels.
*/}}
{{- define "generic-app-chart.labels" -}}
helm.sh/chart: {{ include "generic-app-chart.chart" . }}
{{ include "generic-app-chart.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
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
M8 scaling & disruption — R44. The replica count actually in effect once the
persistence/autoscaling coupling (deployment.yaml) is applied: persistence
pins it to 1 (R19, a Longhorn RWO volume can only attach to one pod),
autoscaling floors it at minReplicas (R25, the HPA owns the count from there),
otherwise the static replicaCount applies. Used to gate the PDB (pdb.yaml) so
a minAvailable/maxUnavailable budget can never target a single-replica
workload, which would deadlock a node drain.
*/}}
{{- define "generic-app-chart.effectiveReplicaCount" -}}
{{- if .Values.persistence.enabled -}}
1
{{- else if .Values.autoscaling.enabled -}}
{{- .Values.autoscaling.minReplicas -}}
{{- else -}}
{{- .Values.replicaCount -}}
{{- end -}}
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
