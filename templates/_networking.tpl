{{/*
M5 networking — R21, R22, R23. Shared helper reused by httproute.yaml and
referencegrant.yaml: the effective Gateway namespace, defaulting to this
release's namespace when the caller doesn't override it (R23's "unset Gateway
namespace defaults to the release namespace" case).
*/}}
{{- define "generic-app-chart.gatewayNamespace" -}}
{{- default .Release.Namespace .Values.routing.gateway.namespace -}}
{{- end }}

{{/*
M5 networking — R22, R23. Shared helper reused by certificate.yaml and
referencegrant.yaml: the effective TLS Secret name, defaulting to
"<fullname>-tls" when the caller doesn't override it. Keeping this in one
place means the ReferenceGrant's scoped grant (R23) can never drift from the
name the Certificate (R22) actually requests.
*/}}
{{- define "generic-app-chart.tlsSecretName" -}}
{{- default (printf "%s-tls" (include "generic-app-chart.fullname" .)) .Values.routing.tls.secretName -}}
{{- end }}
