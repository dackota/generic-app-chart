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
port, i.e. service.ports[0].targetPort), default (bool), name (the probe
field's name, e.g. "readinessProbe" — used only for the fail message below).
Returns the probe body (everything nested under
livenessProbe:/readinessProbe:/startupProbe:) or an empty string when the
probe should be omitted entirely.

The shorthand body (and any pass-through extra fields) is always assembled as
a Go dict and rendered via toYaml — never by hand-formatting strings — so
arbitrary scalar/non-scalar values (a path containing ": ", a list-valued
field, ...) always round-trip as valid YAML instead of risking a broken
render or a crash.
*/}}
{{- define "generic-app-chart.probe" -}}
{{- $value := .value -}}
{{- $isRaw := false -}}
{{- range list "httpGet" "tcpSocket" "exec" "grpc" -}}
{{- if hasKey $value . -}}{{- $isRaw = true -}}{{- end -}}
{{- end -}}
{{- if $isRaw -}}
{{/* A raw block wins outright; drop any stray shorthand keys (path/port)
that may have been left in the same map so they don't leak into the output
as invalid sibling fields alongside httpGet/tcpSocket/exec/grpc. */}}
{{- toYaml (omit $value "path" "port") -}}
{{- else if or (hasKey $value "path") (hasKey $value "port") .default -}}
{{/* Presence-check the port explicitly (hasKey), not `default`/truthiness:
Sprig's `default` treats an explicit `port: 0` as empty and would silently
replace it with the primary service port. */}}
{{- $port := .port -}}
{{- if hasKey $value "port" -}}
{{- $port = $value.port -}}
{{- else if not $port -}}
{{- fail (printf "generic-app-chart: %s has no port to probe — set service.ports or the probe's own port field" (.name | default "this probe")) -}}
{{- end -}}
{{- $extra := omit $value "path" "port" -}}
{{- $shorthand := dict -}}
{{- if hasKey $value "path" -}}
{{- $shorthand = dict "httpGet" (dict "path" $value.path "port" $port) -}}
{{- else -}}
{{- $shorthand = dict "tcpSocket" (dict "port" $port) -}}
{{- end -}}
{{- toYaml (merge $shorthand $extra) -}}
{{- end -}}
{{- end -}}
