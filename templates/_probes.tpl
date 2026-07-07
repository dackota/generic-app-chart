{{/*
M3 workload (deployment.yaml) — R36. Expands one probe's values entry
(livenessProbe/readinessProbe/startupProbe) into its rendered body, in
priority order:

  1. Raw native corev1.Probe — any of httpGet/tcpSocket/exec/grpc already
     present — rendered verbatim, overriding shorthand/default.
  2. Shorthand — {path, port, ...} for an HTTP probe (path present) or
     {port, ...} for a TCP probe (port present, no path); any other native
     Probe field (initialDelaySeconds, periodSeconds, ...) passes through
     alongside.
  3. Empty — renders nothing, *except* when "default" is set, which
     synthesizes a tcpSocket probe on the primary service port. Only
     readinessProbe passes "default": a bad default liveness/startup probe
     would cause restart loops, so those stay opt-in with no fallback.

Takes a dict: value (the values.yaml probe entry), port (the primary service
port, i.e. service.ports[0].targetPort), default (bool). Returns the probe
body (everything nested under livenessProbe:/readinessProbe:/startupProbe:)
or an empty string when the probe should be omitted entirely.
*/}}
{{- define "generic-app-chart.probe" -}}
{{- $value := .value -}}
{{- $isRaw := false -}}
{{- range list "httpGet" "tcpSocket" "exec" "grpc" -}}
{{- if hasKey $value . -}}{{- $isRaw = true -}}{{- end -}}
{{- end -}}
{{- if $isRaw -}}
{{- toYaml $value -}}
{{- else if or (hasKey $value "path") (hasKey $value "port") .default -}}
{{- $port := $value.port | default .port -}}
{{- $extra := omit $value "path" "port" -}}
{{- $lines := list -}}
{{- if hasKey $value "path" -}}
{{- $lines = append $lines "httpGet:" -}}
{{- $lines = append $lines (printf "  path: %s" $value.path) -}}
{{- $lines = append $lines (printf "  port: %v" $port) -}}
{{- else -}}
{{- $lines = append $lines "tcpSocket:" -}}
{{- $lines = append $lines (printf "  port: %v" $port) -}}
{{- end -}}
{{- range $k, $v := $extra -}}
{{- $lines = append $lines (printf "%s: %v" $k $v) -}}
{{- end -}}
{{- join "\n" $lines -}}
{{- end -}}
{{- end -}}
