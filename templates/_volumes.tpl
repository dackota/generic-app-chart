{{/*
Auxiliary to M2/M4 — the pod's volumes and the container's matching
volumeMounts, derived from three sources: the merged container
securityContext's readOnlyRootFilesystem (R11's automatic /tmp emptyDir),
values.extraEmptyDirs (R11's additional writable mounts), and
values.persistence (R18). Centralized here so deployment.yaml doesn't
duplicate the "which sources are active" branching once for volumeMounts and
once for volumes.
*/}}

{{- define "generic-app-chart.volumeMounts" -}}
{{- $containerSecurityContext := include "generic-app-chart.containerSecurityContext" . | fromYaml -}}
{{- if $containerSecurityContext.readOnlyRootFilesystem }}
- name: tmp
  mountPath: /tmp
{{- end }}
{{- range .Values.extraEmptyDirs }}
- name: {{ .name }}
  mountPath: {{ .mountPath }}
{{- end }}
{{- if .Values.persistence.enabled }}
- name: data
  mountPath: {{ .Values.persistence.mountPath }}
{{- end }}
{{- end }}

{{- define "generic-app-chart.volumes" -}}
{{- $containerSecurityContext := include "generic-app-chart.containerSecurityContext" . | fromYaml -}}
{{- if $containerSecurityContext.readOnlyRootFilesystem }}
- name: tmp
  emptyDir: {}
{{- end }}
{{- range .Values.extraEmptyDirs }}
- name: {{ .name }}
  emptyDir:
    {{- if .sizeLimit }}
    sizeLimit: {{ .sizeLimit }}
    {{- else }}
    {}
    {{- end }}
{{- end }}
{{- if .Values.persistence.enabled }}
- name: data
  persistentVolumeClaim:
    claimName: {{ .Values.persistence.existingClaim | default (include "generic-app-chart.fullname" .) }}
{{- end }}
{{- end }}
