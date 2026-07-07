# generic-app-chart

A reusable, security-hardened Helm chart for deploying personal applications on a
home-lab Kubernetes cluster. Renders a complete app — Deployment, Service,
ServiceAccount, ConfigMap, optional persistence, Gateway API routing +
cert-manager TLS, and opt-in HPA/PDB/NetworkPolicy — from a single
`values.yaml`, with restricted-PSA security defaults applied out of the box.

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
  `imagePullSecrets` references existing image-pull Secret(s) by name for
  private-registry pulls, omitted entirely when unset. `extraVolumes`/
  `extraVolumeMounts` accept arbitrary native Volume/VolumeMount shapes (e.g. a
  referenced Secret or ConfigMap volume), assembled through the same
  `_volumes.tpl` partial as the automatic `/tmp` emptyDir, `extraEmptyDirs`,
  and the persistence PVC — all of them coexist.
- **Service** (`templates/service.yaml`) — `ClusterIP` by default (overridable
  via `service.type`), mapping `service.ports` onto the pod's container ports.
- **ServiceAccount** (`templates/serviceaccount.yaml`) — a dedicated SA per
  app by default; set `serviceAccount.create: false` to reuse an existing one.
- **ConfigMap** (`templates/configmap.yaml`) — rendered from `config` when
  non-empty; the Deployment carries a `checksum/config` pod annotation so
  editing `config` triggers a rollout.
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
  exclusive by construction — see "Persistence" below).
- **PodDisruptionBudget** (`templates/pdb.yaml`) — rendered when `pdb.enabled`,
  using `minAvailable` by default or `maxUnavailable` when set (mutually
  exclusive).
- **NetworkPolicy** (`templates/networkpolicy.yaml`) — rendered when
  `networkPolicy.enabled`; default-deny ingress except from the configured
  gateway namespace/pods, with optional additional egress allowances.
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
- `automountServiceAccountToken: false` at the pod level.
- Container resource `requests` and `limits` are always set.

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

## Autoscaling, PodDisruptionBudget, and NetworkPolicy

- `autoscaling.enabled: true` renders an HPA (`minReplicas`/`maxReplicas`,
  CPU/memory target utilization); the Deployment's static `replicas` is
  omitted once the HPA owns replica count. Mutually exclusive with
  `persistence.enabled` (see above).
- `pdb.enabled: true` renders a PodDisruptionBudget using `minAvailable`
  (default `1`) or `maxUnavailable` when set.
- `networkPolicy.enabled: true` renders a default-deny-ingress NetworkPolicy
  that allows only the configured `networkPolicy.gateway`
  namespace/pod-selector; `networkPolicy.additionalEgress` supplies optional
  egress allowances (native `NetworkPolicyEgressRule` entries).

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
key collides with one of them.

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

## Testing

```bash
helm lint .
helm unittest .
```

Suites live under `tests/*_test.yaml` (one per module: naming/labels,
security defaults, workload, persistence, config, service, serviceaccount,
HTTPRoute, Certificate, ReferenceGrant, HPA, PDB, NetworkPolicy, ServiceMonitor,
plus the R28 secret, R12 security opt-out, R24 cluster-only, and R25
HPA<->persistence property/invariant suites). Named scenario values files
live under `tests/values/`:

- `default.yaml` — minimal/base case (stateless app).
- `persistent.yaml` — persistence enabled (stateful app).
- `autoscaling.yaml` — HPA enabled (stateless, scaling app).
- `networkpolicy.yaml` — default-deny NetworkPolicy enabled.
- `cluster-only.yaml` — routing disabled, NetworkPolicy enabled (internal,
  locked-down app).
- `full.yaml` — routing + TLS through a cross-namespace Gateway, autoscaling,
  PDB, NetworkPolicy, the observability surface, and generic metadata
  passthrough all together.
