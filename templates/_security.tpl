{{/*
M2 security defaults — R9, R10, R11, R12, R13.

Deep, reusable helper producing the restricted-PSA-compliant pod- and
container-level securityContext blocks. Every default is merged field-by-field
with `.Values.podSecurityContext` / `.Values.containerSecurityContext`
(mergeOverwrite over a deep copy of the chart defaults) so an app can override
exactly one field (e.g. a specific runAsUser) without disabling the rest of
the strict security posture (R12). M3's Deployment template calls into this.
*/}}

{{/*
Chart-default pod-level securityContext, as a dict (not yet merged with user
overrides). Kept separate so both the merge helper and any caller that needs
the raw defaults can share one source of truth.
*/}}
{{- define "generic-app-chart.podSecurityContextDefaults" -}}
{{- dict "runAsNonRoot" true "runAsUser" 10001 "runAsGroup" 10001 "fsGroup" 10001 "seccompProfile" (dict "type" "RuntimeDefault") | toYaml -}}
{{- end }}

{{/*
Merged pod-level securityContext: chart defaults with per-field opt-out via
.Values.podSecurityContext. Renders as YAML ready to nest under
`securityContext:`.
*/}}
{{- define "generic-app-chart.podSecurityContext" -}}
{{- $defaults := include "generic-app-chart.podSecurityContextDefaults" . | fromYaml -}}
{{- $user := .Values.podSecurityContext | default dict -}}
{{- mergeOverwrite (deepCopy $defaults) $user | toYaml -}}
{{- end }}

{{/*
Chart-default container-level securityContext, as a dict.
*/}}
{{- define "generic-app-chart.containerSecurityContextDefaults" -}}
{{- dict "allowPrivilegeEscalation" false "readOnlyRootFilesystem" true "privileged" false "capabilities" (dict "drop" (list "ALL")) | toYaml -}}
{{- end }}

{{/*
Merged container-level securityContext: chart defaults with per-field opt-out
via .Values.containerSecurityContext. Renders as YAML ready to nest under
`securityContext:`.
*/}}
{{- define "generic-app-chart.containerSecurityContext" -}}
{{- $defaults := include "generic-app-chart.containerSecurityContextDefaults" . | fromYaml -}}
{{- $user := .Values.containerSecurityContext | default dict -}}
{{- mergeOverwrite (deepCopy $defaults) $user | toYaml -}}
{{- end }}
