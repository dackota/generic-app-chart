{{/*
M5 networking — R21, R22, R23. Shared helper reused by httproute.yaml and
referencegrant.yaml: the effective Gateway namespace, defaulting to this
release's namespace when the caller doesn't override it (R23's "unset Gateway
namespace defaults to the release namespace" case).
*/}}
{{- define "generic-app-chart.gatewayNamespace" -}}
{{- default .Release.Namespace .Values.routing.gateway.namespace -}}
{{- end }}
