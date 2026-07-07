{{/*
Naming/labels.

Every rendered resource derives its name and labels through these helpers so
naming and labelling stay consistent across the whole chart (Deployment,
Service, ServiceAccount, ConfigMap, PVC, and every other resource this chart
renders).
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
Chart-managed labels only — selector labels plus helm.sh/chart, version, and
managed-by — with no commonLabels folded in. This is the raw "managed" side
used both by generic-app-chart.labels below (which folds commonLabels in) and
by generic-app-chart.podLabels (_metadata.tpl), which needs the unfolded set
so podLabels can correctly outrank commonLabels for the same key on the pod
template — merging against the already-commonLabels-folded
generic-app-chart.labels output would let any commonLabels key silently beat
podLabels instead.
*/}}
{{- define "generic-app-chart.managedLabels" -}}
{{- $selector := include "generic-app-chart.selectorLabels" . | fromYaml -}}
{{- merge $selector (dict "helm.sh/chart" (include "generic-app-chart.chart" .) "app.kubernetes.io/version" .Chart.AppVersion "app.kubernetes.io/managed-by" .Release.Service) | toYaml -}}
{{- end }}

{{/*
Standard Helm common labels, merged with .Values.commonLabels so every
resource that renders through this shared helper picks up commonLabels
automatically, without each template bolting the merge on individually.
Chart-managed keys (helm.sh/chart, the selector labels, version, managed-by)
always win on conflict — letting commonLabels override
app.kubernetes.io/name/instance would break the selectors that depend on them
elsewhere in the chart.
*/}}
{{- define "generic-app-chart.labels" -}}
{{- $managed := include "generic-app-chart.managedLabels" . | fromYaml -}}
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
The replica count actually in effect once the persistence/autoscaling
coupling (deployment.yaml) is applied: persistence pins it to 1 (a Longhorn
RWO volume can only attach to one pod), autoscaling floors it at minReplicas
(the HPA owns the count from there), otherwise the static replicaCount
applies. Used to gate the PDB (pdb.yaml) so a minAvailable/maxUnavailable
budget can never target a single-replica workload, which would deadlock a
node drain.
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
Name of the ServiceAccount the Deployment runs as. When
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
