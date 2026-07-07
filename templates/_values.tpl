{{/*
Auxiliary to the workload template — generic "is this a real, meaningful override" check
for scalar values that default to the sentinel "" in values.yaml
(revisionHistoryLimit, minReadySeconds, updateStrategy.maxSurge/
maxUnavailable). Truthiness (`{{- with .Values.X }}`) and a bare
`toString .Values.X != ""` guard both fail this contract in their own way:
truthiness drops an explicit 0, and toString turns a nil into the literal
string "<nil>" (which is != ""), so an explicit `null` override renders as a
dangling empty-scalar key instead of being omitted. Confirmed empirically
(`helm template` against unset/0/null values files): Helm's merge drops the
key entirely when a caller sets it to `null`, which surfaces here as
`kindIs "invalid"` — the same signal Go templates use for "no such key" — so
checking both "not invalid" and "not the empty-string sentinel" in one place
covers unset, explicit 0, and explicit null correctly for every caller of
this helper.
*/}}

{{- define "generic-app-chart.isSet" -}}
{{- if and (not (kindIs "invalid" .)) (ne (toString .) "") -}}
true
{{- end -}}
{{- end -}}
