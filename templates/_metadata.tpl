{{/*
M1 generic metadata passthrough — R39.

podAnnotations/podLabels (pod template only), commonLabels/commonAnnotations
(every rendered resource), and serviceAnnotations (Service only), all merged
with — and always overridden by — this chart's managed labels/annotations:
selector labels (_helpers.tpl) and the checksum/config annotation (R17,
configmap.yaml/deployment.yaml). commonLabels already flows into every
resource's own metadata.labels through generic-app-chart.labels itself
(_helpers.tpl); the pod-template labels below re-merge commonLabels against
the raw chart-managed set directly (not through generic-app-chart.labels) so
podLabels can correctly outrank commonLabels for the same key — the helpers
below layer these, and the remaining, more targeted overrides, on top.
*/}}

{{/*
Resource metadata.annotations for every template that has no annotations of
its own to merge in: just .Values.commonAnnotations, rendered only when
non-empty so callers can safely `with` the result.
*/}}
{{- define "generic-app-chart.annotations" -}}
{{- with .Values.commonAnnotations }}
{{- toYaml . }}
{{- end }}
{{- end }}

{{/*
Pod template labels: .Values.commonLabels and .Values.podLabels merged with
the chart-managed label set (selector labels, helm.sh/chart, version,
managed-by), mirroring generic-app-chart.podAnnotations' shape below.
podLabels — the more specific of the two user sources — wins over
commonLabels on conflict, and chart-managed labels always win over both; the
Deployment's own selector depends on them staying stable. Deliberately merges
against the raw chart-managed set (generic-app-chart.managedLabels) rather
than the commonLabels-folded generic-app-chart.labels output — merging
against that pre-folded result would let any commonLabels key unconditionally
beat podLabels for the same key, backwards from the intended precedence.
*/}}
{{- define "generic-app-chart.podLabels" -}}
{{- $managed := include "generic-app-chart.managedLabels" . | fromYaml -}}
{{- $common := .Values.commonLabels | default dict -}}
{{- $pod := .Values.podLabels | default dict -}}
{{- $merged := mergeOverwrite (deepCopy $common) $pod -}}
{{- mergeOverwrite $merged $managed | toYaml -}}
{{- end }}

{{/*
Pod template annotations: .Values.commonAnnotations and .Values.podAnnotations
merged with the chart-managed checksum/config annotation (R17), which is only
present when .Values.config is set. checksum/config always wins on conflict —
it's what forces a rollout when config data changes, so a user-supplied
override under the same key must never be allowed to silence it. Renders
nothing when the merged result is empty, so callers can safely `with` it.
*/}}
{{- define "generic-app-chart.podAnnotations" -}}
{{- $common := .Values.commonAnnotations | default dict -}}
{{- $pod := .Values.podAnnotations | default dict -}}
{{- $merged := mergeOverwrite (deepCopy $common) $pod -}}
{{- if .Values.config -}}
{{- $merged = mergeOverwrite $merged (dict "checksum/config" (include (print .Template.BasePath "/configmap.yaml") . | sha256sum)) -}}
{{- end -}}
{{- if $merged -}}
{{- toYaml $merged -}}
{{- end -}}
{{- end }}

{{/*
Low-level merge shared by every "commonAnnotations plus one resource-specific
annotations field" helper below: merges two annotation dicts, "specific"
winning on conflict, and renders as YAML — or nothing when the merged result
is empty, so callers can safely `with` it. Takes a dict argument ("common",
"specific") since named templates only accept a single context.
*/}}
{{- define "generic-app-chart.mergeAnnotations" -}}
{{- $common := .common | default dict -}}
{{- $specific := .specific | default dict -}}
{{- $merged := mergeOverwrite (deepCopy $common) $specific -}}
{{- if $merged -}}
{{- toYaml $merged -}}
{{- end -}}
{{- end }}

{{/*
Service metadata.annotations: .Values.commonAnnotations merged with
.Values.serviceAnnotations. Neither is chart-managed, so serviceAnnotations —
the more specific of the two — wins on conflict rather than being dropped.
*/}}
{{- define "generic-app-chart.serviceAnnotations" -}}
{{- include "generic-app-chart.mergeAnnotations" (dict "common" .Values.commonAnnotations "specific" .Values.serviceAnnotations) -}}
{{- end }}

{{/*
ServiceAccount metadata.annotations: .Values.commonAnnotations merged with
.Values.serviceAccount.annotations (R14), the latter — the more specific of
the two — winning on conflict.
*/}}
{{- define "generic-app-chart.serviceAccountAnnotations" -}}
{{- include "generic-app-chart.mergeAnnotations" (dict "common" .Values.commonAnnotations "specific" .Values.serviceAccount.annotations) -}}
{{- end }}
