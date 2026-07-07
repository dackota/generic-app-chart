# generic-app-chart

A reusable, security-hardened Helm chart for deploying personal applications on a
home-lab Kubernetes cluster. Renders a complete app — Deployment, Service,
ServiceAccount, ConfigMap, optional persistence, and Gateway API routing/TLS —
from a single `values.yaml`, with restricted-PSA security defaults applied
out of the box.

Published to `oci://ghcr.io/dackota/charts/generic-app-chart`.
