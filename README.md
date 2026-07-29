# generic-app-chart

A reusable, security-hardened Helm chart for deploying applications on a Kubernetes cluster. Renders a complete app — Deployment, Service,
ServiceAccount, ConfigMap, optional persistence, Gateway API routing +
cert-manager TLS, opt-in HPA, and default-on PDB/NetworkPolicy — from a single
`values.yaml`, with restricted-PSA security defaults applied out of the box.
Every best-practice default is opt-out via `values.yaml`; the chart is built
for the one-app-per-namespace model, and can optionally render the namespace
itself with Pod Security Admission labels enforcing the restricted profile.

Published to `oci://ghcr.io/dackota/charts/generic-app-chart`.

## Prerequisites

This chart declares `kubeVersion: ">=1.27.0-0"` in `Chart.yaml`.

The cluster capabilities below are prerequisites for the **whole app surface**
this chart renders:

| Capability | Used by | Status in this chart |
|---|---|---|
| **Longhorn** (`storageClass: longhorn`) | `persistence.enabled` PVC (`templates/pvc.yaml`) | Implemented |
| **metrics-server** | HPA target metrics (`templates/hpa.yaml`) | Implemented |
| **Gateway API** (Traefik as the implementation) | HTTPRoute, ReferenceGrant | Implemented |
| **cert-manager** + a `letsencrypt` ClusterIssuer | Certificate | Implemented |
| **prometheus-operator CRDs** | `metrics.serviceMonitor.enabled` ServiceMonitor (`templates/servicemonitor.yaml`) | Implemented |

## Installing

```bash
helm install my-app oci://ghcr.io/dackota/charts/generic-app-chart --version <x.y.z> \
  -f values.yaml
```

A consuming `gitops/workloads/<app>` typically vendors this chart as a
dependency in its own thin `Chart.yaml` plus a `values.yaml` — see the
`personal-generic-app-chart` PRD for that pattern.

## What this chart renders

- **Deployment** (`templates/deployment.yaml`) — the workload container, built
  from `image.*`, `command`/`args`, `env`/`envFrom`, probes, and resources.
  Set `image.digest` to pin the image by immutable digest instead of tag.
  `initContainers`/`extraContainers` pass native Container entries through
  verbatim (migrations, sidecars) — give each its own `securityContext`, since
  they don't inherit the chart's container defaults.
  `imagePullSecrets` references existing image-pull Secret(s) by name for
  private-registry pulls, omitted entirely when unset. `extraVolumes`/
  `extraVolumeMounts` accept arbitrary native Volume/VolumeMount shapes (e.g. a
  referenced Secret or ConfigMap volume), assembled through the same
  `_volumes.tpl` partial as the automatic `/tmp` emptyDir, `extraEmptyDirs`,
  and the persistence PVC — all of them coexist. `livenessProbe`/
  `readinessProbe`/`startupProbe` each accept a raw native Probe block, a
  `{path, port}`/`{port}` shorthand, or (readiness only) fall back to a
  `tcpSocket` check on the primary service port when left unset — see the
  comments in `values.yaml`.
- **Service** (`templates/service.yaml`) — `ClusterIP` by default (overridable
  via `service.type`), mapping `service.ports` onto the pod's container ports.
- **ServiceAccount** (`templates/serviceaccount.yaml`) — a dedicated SA per
  app by default; set `serviceAccount.create: false` to reuse an existing one.
- **ConfigMap** (`templates/configmap.yaml`) — rendered from `config` when
  non-empty. Set `configChecksumAnnotation: true` to also stamp a
  `checksum/config` pod annotation so editing `config` triggers a rollout;
  it is **off by default** (see below).
- **PersistentVolumeClaim** (`templates/pvc.yaml`) — an RWO Longhorn volume,
  rendered only when `persistence.enabled` and no `persistence.existingClaim`
  is supplied.
- **HTTPRoute** (`templates/httproute.yaml`) — a Gateway API route to this
  chart's Service, rendered only when `routing.enabled`; parentRef
  name/namespace/sectionName target the lab's one shared Gateway.
- **Certificate** (`templates/certificate.yaml`) — a cert-manager Certificate
  for `routing.hostnames`, rendered when `routing.enabled` and
  `routing.tls.enabled` (on by default), issued via the `letsencrypt`
  ClusterIssuer by default.
- **ReferenceGrant** (`templates/referencegrant.yaml`) — authorizes the
  Gateway's namespace to reach this namespace's Service/Secret, rendered only
  when routing is enabled and the Gateway lives in a different namespace than
  this release; omitted entirely when they match.
- **HorizontalPodAutoscaler** (`templates/hpa.yaml`) — rendered when
  `autoscaling.enabled`, unless `persistence.enabled` (the two are mutually
  exclusive by construction — see "Persistence" below). `autoscaling.behavior`
  passes native scaleUp/scaleDown behavior through verbatim.
- **PodDisruptionBudget** (`templates/pdb.yaml`) — **on by default**
  (`pdb.enabled: true`), but only rendered when the effective replica count
  is > 1, so it can never deadlock a single-replica drain. Uses `minAvailable`
  by default or `maxUnavailable` when set (mutually exclusive), plus
  `unhealthyPodEvictionPolicy: AlwaysAllow` so a crash-looping app can't wedge
  a node drain.
- **NetworkPolicy** (`templates/networkpolicy.yaml`) — **on by default**
  (`networkPolicy.enabled: true`); default-deny ingress with allowances
  derived from what the app enables — see "NetworkPolicy" below.
- **Namespace** (`templates/namespace.yaml`) — opt-in (`namespace.create`);
  renders the release namespace itself with Pod Security Admission labels
  (restricted by default) — see "Namespace-per-app" below.
- **ServiceMonitor** (`templates/servicemonitor.yaml`) — rendered when
  `metrics.serviceMonitor.enabled`, selecting this chart's own Service on a
  named metrics port for Prometheus Operator to scrape.

This chart never renders a Secret resource. It consumes existing in-cluster
Secrets only, via `envFrom.secretRef` / `env[].valueFrom.secretKeyRef` — see
CONTEXT.md's "referenced Secret". Getting a Secret into the cluster is a
platform concern outside this chart.

## Strict security defaults

Every app rendered by this chart ships restricted-PSA-compliant by default:

- Pod: `runAsNonRoot: true`, non-zero `runAsUser`/`runAsGroup`/`fsGroup`,
  `seccompProfile.type: RuntimeDefault`.
- Container: `allowPrivilegeEscalation: false`, `readOnlyRootFilesystem: true`
  (paired with an automatic `/tmp` `emptyDir` so a read-only root filesystem
  doesn't break apps that write temp files), `privileged: false`,
  `capabilities.drop: [ALL]`.
- `automountServiceAccountToken: false` at the pod level, mirrored onto the
  ServiceAccount resource itself so any other pod reusing the SA inherits the
  same no-token default.
- `enableServiceLinks: false` — no legacy Docker-link env vars leaking every
  Service in the namespace into the pod environment.
- A default-deny-ingress **NetworkPolicy** (below).
- Container resource `requests` and `limits` are always set.
- Optional `image.digest` pins the image by immutable digest so deployed bits
  can't drift under a re-pushed tag.

Every one of these is **independently overridable** via
`podSecurityContext`/`containerSecurityContext`/`automountServiceAccountToken`
— setting one field never disables the rest of the posture. See the comments
in `values.yaml` for the override shape.

## Persistence

Set `persistence.enabled: true` to get an RWO Longhorn PVC mounted at
`persistence.mountPath`. Enabling persistence forces the Deployment to
`strategy: Recreate` and pins `replicas: 1` — a Longhorn RWO volume can only
be attached to one pod at a time, so persistence and autoscaling are mutually
exclusive by construction: `templates/hpa.yaml` never renders while
`persistence.enabled` is true, regardless of `autoscaling.enabled`.

## Routing, TLS, and cluster-only mode

Set `routing.enabled: true` to expose the app through the lab's one shared
Traefik Gateway: an `HTTPRoute` is rendered **in this app's own namespace**
with `routing.hostnames`, a `parentRef` to
`routing.gateway.{name,namespace,sectionName}`, and a `backendRef` to this
chart's own Service — same-namespace, so it needs no cross-namespace grant.
TLS is issued automatically (`routing.tls.enabled: true` by default) via a
cert-manager `Certificate`, also in this app's own namespace, against the
configured `issuerRef`, targeting `routing.tls.secretName` (defaults to
`<fullname>-tls`).

This is the Gateway API project's own documented multi-tenancy pattern (ADR
0001): apps self-serve their own Route + Certificate; the platform's shared
Gateway opts in via `allowedRoutes` on its listener(s) and only needs a
`ReferenceGrant` for the one genuinely cross-namespace reference this
creates — its own listener reading this app's TLS Secret. That
`ReferenceGrant` is rendered automatically when TLS is enabled and the
Gateway's namespace differs from the release namespace; omitted when they're
the same namespace or TLS is off.

**Platform prerequisite, outside this chart's control:** the shared Gateway's
listener(s) must set `allowedRoutes: {namespaces: {from: All}}` (or a
narrower `Selector`) for this app's own-namespace `HTTPRoute` to attach at
all, and each new app's Certificate Secret name must be added to that
listener's own `certificateRefs` list.

Leaving `routing.enabled: false` (the default) is cluster-only mode: no
HTTPRoute/Certificate/ReferenceGrant renders, while the Service keeps
rendering as normal for in-cluster access.

## Autoscaling and PodDisruptionBudget

- `autoscaling.enabled: true` renders an HPA (`minReplicas`/`maxReplicas`,
  CPU/memory target utilization, optional native `behavior` passthrough); the
  Deployment's static `replicas` is omitted once the HPA owns replica count.
  Mutually exclusive with `persistence.enabled` (see above).
- The PDB is on by default but renders only for effectively multi-replica
  workloads (static `replicaCount` > 1 or an autoscaling floor > 1). It uses
  `minAvailable` (default `1`) or `maxUnavailable` when set, and
  `unhealthyPodEvictionPolicy: AlwaysAllow` (set `""` to omit). Set
  `pdb.enabled: false` to opt out.

## NetworkPolicy

On by default: a default-deny-ingress NetworkPolicy scoped to this app's
pods, with allowances **derived from what the app actually enables**:

- pods in the app's own namespace (`networkPolicy.allowSameNamespace`,
  default true — intra-app traffic under the one-app-per-namespace model);
- the gateway namespace/pods (`networkPolicy.gateway`), only while
  `routing.enabled` — a cluster-only app never opens a hole for the gateway;
- the monitoring namespace (`networkPolicy.monitoring`), only while the
  metrics surface (`metrics.scrape` or `metrics.serviceMonitor`) is enabled;
- anything under `networkPolicy.additionalIngress` (native
  `NetworkPolicyIngressRule` entries).

Egress stays unrestricted until `networkPolicy.restrictEgress: true` or any
`networkPolicy.additionalEgress` rule activates egress restriction; once
active, DNS to kube-system's `kube-dns` is allowed automatically
(`networkPolicy.allowDNS`, default true) so a locked-down app can still
resolve names. Set `networkPolicy.enabled: false` to opt out entirely.

## Namespace-per-app and Pod Security Admission

The chart assumes each app lives in its own namespace. `namespace.create:
true` (default false) additionally renders the release namespace itself,
labeled with Pod Security Admission levels (`namespace.podSecurityStandards`,
`restricted` for enforce/audit/warn by default) — so the restricted posture
the chart renders into pod specs is also *enforced* by the API server for
everything in the namespace, sidecars and manual `kubectl run` included.

It is opt-in because namespace ownership can't be assumed: with plain
`helm install --create-namespace` or a pre-created namespace, Helm cannot
adopt the existing object, and `helm uninstall` deletes a chart-owned
namespace with everything in it. Under ArgoCD, either enable it (the
Application then owns the namespace) or keep using
`CreateNamespace=true` with `managedNamespaceMetadata` to apply the PSA
labels instead.

## Observability surface

Both off by default:

- `metrics.scrape.enabled: true` renders `prometheus.io/scrape: "true"`,
  `prometheus.io/port`, and `prometheus.io/path` pod annotations via the
  generic metadata passthrough mechanism above (`_metadata.tpl`) — merged
  with (never dropping) any `podAnnotations`/`commonAnnotations` already set,
  the same way `checksum/config` is.
- `metrics.serviceMonitor.enabled: true` renders a
  `monitoring.coreos.com/v1` ServiceMonitor (`templates/servicemonitor.yaml`)
  selecting this chart's own Service by its stable selector labels, scraping
  the named port/path configured under `metrics.serviceMonitor.port`/`.path`
  (that port name must already exist under `service.ports`). Requires the
  prometheus-operator CRDs to be installed cluster-side.

This is infra-only: it does not instrument application code with RED
metrics, and it does not wire a custom-metric HPA off scraped values.

## Generic metadata passthrough

- `podAnnotations`/`podLabels` add to the pod template only, merged with (and
  never overriding) the chart-managed pod labels/selector labels and the
  `checksum/config` annotation.
- `commonLabels`/`commonAnnotations` add to **every** resource this chart
  renders, merged with (and never overriding) that resource's chart-managed
  labels/annotations.
- `serviceAnnotations` adds to the Service only, merged with
  `commonAnnotations` (`serviceAnnotations` wins on conflict, being the more
  specific of the two).

Chart-managed keys — selector labels, `helm.sh/chart`, `app.kubernetes.io/*`,
and the `checksum/config` rollout trigger — always win when a user-supplied
key collides with one of them. (`checksum/config` is only chart-managed while
`configChecksumAnnotation` is true; with it off there is no chart value to
protect and a user-supplied `checksum/config` passes through untouched.)

## Config rollout trigger

`configChecksumAnnotation` (default `false`) controls whether the Deployment
carries a `checksum/config` pod annotation derived from `config`.

It is off by default because of how these apps are deployed. Under ArgoCD an
always-on checksum turns every config edit into a full rollout, whether or not
the app needs one — and most apps here either hot-reload their config or read
it at startup on a cadence where an operator-triggered restart is fine. Turn it
on per app when a config change genuinely must restart the process to take
effect.

The digest covers `config` and nothing else. It deliberately does **not** hash
the rendered ConfigMap: that render carries
`helm.sh/chart: <name>-<Chart.Version>` in its labels, so hashing it made the
annotation change on every chart version bump and roll every pod on upgrades
that touched no config at all — the failure mode this flag exists to end.
Enabling the flag therefore restarts pods when config changes, not when the
chart is upgraded.

## Publishing

Releases are cut by [release-please](https://github.com/googleapis/release-please)
(`release-please-config.json` / `.release-please-manifest.json`, `release-type:
helm`, bumping `Chart.yaml`'s `version`). On a `v*` tag, `.github/workflows/release.yml`
packages the chart and pushes it to `oci://ghcr.io/dackota/charts/generic-app-chart`
using the workflow's `GITHUB_TOKEN` (`packages: write`) for GHCR auth.

**Manual one-time step:** GHCR packages default to private. After the first
publish, a repo maintainer must set the `generic-app-chart` package's
visibility to **public** by hand in GitHub (Package settings → Change
visibility) — this cannot be done from a workflow file, and its absence is
not a CI failure.

## Values validation

`values.schema.json` validates values at lint/install/upgrade time: top-level
keys are closed (a typo'd key fails fast instead of silently rendering a
default), enums are enforced (`image.pullPolicy`, `service.type`,
`pdb.unhealthyPodEvictionPolicy`, ...), and `image.digest` must be a real
`sha256:` digest. Native-Kubernetes passthrough shapes (env, probes,
affinity, container specs) stay open on purpose — kubeconform validates the
rendered output against the real Kubernetes schemas in CI.

## Testing

```bash
helm lint .
helm unittest .
```

Suites live under `tests/*_test.yaml` (one per module: naming/labels,
security defaults, workload, persistence, config, service, serviceaccount,
Namespace, HTTPRoute, Certificate, ReferenceGrant, HPA, PDB, NetworkPolicy,
ServiceMonitor, plus the never-renders-a-secret, security opt-out,
cluster-only, and HPA<->persistence property/invariant suites). Named
scenario values files live under `tests/values/`:

- `default.yaml` — minimal/base case (stateless app).
- `persistent.yaml` — persistence enabled (stateful app).
- `autoscaling.yaml` — HPA enabled (stateless, scaling app).
- `networkpolicy.yaml` — default-deny NetworkPolicy enabled.
- `cluster-only.yaml` — routing disabled, NetworkPolicy enabled (internal,
  locked-down app).
- `full.yaml` — routing + TLS through a cross-namespace Gateway, autoscaling,
  PDB, NetworkPolicy, the observability surface, and generic metadata
  passthrough all together.
