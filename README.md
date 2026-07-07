# generic-app-chart

A reusable, security-hardened Helm chart for deploying personal applications on a
home-lab Kubernetes cluster. Renders a complete app — Deployment, Service,
ServiceAccount, ConfigMap, and optional persistence — from a single
`values.yaml`, with restricted-PSA security defaults applied out of the box.

Routing (Gateway API HTTPRoute + cert-manager Certificate + ReferenceGrant),
HPA, PDB, and NetworkPolicy are built on top of this chart by the
`networking-operational-addons` task; this chart's structure deliberately
leaves room for them (e.g. an `hpa.yaml`/`networkpolicy.yaml`/`httproute.yaml`
template can be added later without reshaping what's here).

Published to `oci://ghcr.io/dackota/charts/generic-app-chart`.

## Prerequisites

This chart declares `kubeVersion: ">=1.27.0-0"` in `Chart.yaml`.

The cluster capabilities below are prerequisites for the **whole app surface**
this chart renders across all of its tasks — not all of them are exercised by
what's implemented so far:

| Capability | Used by | Status in this chart |
|---|---|---|
| **Longhorn** (`storageClass: longhorn`) | `persistence.enabled` PVC (`templates/pvc.yaml`) | Implemented |
| **metrics-server** | HPA target metrics | Not yet rendered — lands with `networking-operational-addons` |
| **Gateway API** (Traefik as the implementation) | HTTPRoute | Not yet rendered — lands with `networking-operational-addons` |
| **cert-manager** + a `letsencrypt` ClusterIssuer | Certificate | Not yet rendered — lands with `networking-operational-addons` |

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
exclusive by construction (the HPA template the `networking-operational-addons`
task adds must gate on `persistence.enabled` the same way).

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
plus the R28 and R12 property/invariant suites). Named scenario values files
live under `tests/values/`:

- `default.yaml` — minimal/base case (stateless app).
- `persistent.yaml` — persistence enabled (stateful app).

(`autoscaling.yaml`, `networkpolicy.yaml`, `cluster-only.yaml`, and
`full.yaml` are added by the `networking-operational-addons` task alongside
the features they exercise.)
