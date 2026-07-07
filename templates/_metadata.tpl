{{/*
Generic metadata passthrough.

podAnnotations/podLabels (pod template only), commonLabels/commonAnnotations
(every rendered resource), and serviceAnnotations (Service only), all merged
with — and always overridden by — this chart's managed labels/annotations:
selector labels (_helpers.tpl) and the checksum/config annotation
(configmap.yaml/deployment.yaml). commonLabels already flows into every
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
Prometheus scrape annotations: prometheus.io/scrape|port|path,
rendered only when .Values.metrics.scrape.enabled. Guards against the
"nulled-intermediate-key" panic class by defaulting .Values.metrics and its
.scrape sub-key to an empty dict before reading .enabled/.port/.path, so an
explicit `metrics: null` or `metrics.scrape: null` override falls back to
off rather than crashing the render. Folded into
generic-app-chart.podAnnotations below via the same merge mechanism as
checksum/config, so it combines with — and always wins over — any
commonAnnotations/podAnnotations the caller already set. Renders nothing
when scrape is disabled, so callers can safely `fromYaml` the result.
*/}}
{{- define "generic-app-chart.scrapeAnnotations" -}}
{{- $metrics := .Values.metrics | default dict -}}
{{- $scrape := $metrics.scrape | default dict -}}
{{- if $scrape.enabled }}
prometheus.io/scrape: "true"
prometheus.io/port: {{ $scrape.port | quote }}
prometheus.io/path: {{ $scrape.path | quote }}
{{- end }}
{{- end }}

{{/*
Pod template annotations: .Values.commonAnnotations and .Values.podAnnotations
merged with the chart-managed checksum/config annotation, which is only
present when .Values.config is set, and the scrape annotations above,
which are only present when .Values.metrics.scrape.enabled. Both
chart-derived annotation sets always win on conflict — checksum/config is
what forces a rollout when config data changes, and the scrape annotations
are deterministically derived from .Values.metrics.scrape — so a
user-supplied override under either key must never be allowed to silence
them. Renders nothing when the merged result is empty, so callers can safely
`with` it.
*/}}
{{- define "generic-app-chart.podAnnotations" -}}
{{- $common := .Values.commonAnnotations | default dict -}}
{{- $pod := .Values.podAnnotations | default dict -}}
{{- $merged := mergeOverwrite (deepCopy $common) $pod -}}
{{- if .Values.config -}}
{{- $merged = mergeOverwrite $merged (dict "checksum/config" (include (print .Template.BasePath "/configmap.yaml") . | sha256sum)) -}}
{{- end -}}
{{- $scrapeAnnotations := include "generic-app-chart.scrapeAnnotations" . | fromYaml -}}
{{- if $scrapeAnnotations -}}
{{- $merged = mergeOverwrite $merged $scrapeAnnotations -}}
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
.Values.serviceAccount.annotations, the latter — the more specific of
the two — winning on conflict.
*/}}
{{- define "generic-app-chart.serviceAccountAnnotations" -}}
{{- include "generic-app-chart.mergeAnnotations" (dict "common" .Values.commonAnnotations "specific" .Values.serviceAccount.annotations) -}}
{{- end }}
