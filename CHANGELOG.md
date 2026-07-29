# Changelog

## [2.0.1](https://github.com/dackota/generic-app-chart/compare/v2.0.0...v2.0.1) (2026-07-29)


### Bug Fixes

* **renovate:** trigger a run when Dependency Dashboard checkboxes are clicked ([#28](https://github.com/dackota/generic-app-chart/issues/28)) ([0c2892b](https://github.com/dackota/generic-app-chart/commit/0c2892b7e3c21285d63d976b0f48864156702172))

## [2.0.0](https://github.com/dackota/generic-app-chart/compare/v1.0.0...v2.0.0) (2026-07-29)


### ⚠ BREAKING CHANGES

* default NetworkPolicy/PDB on, add namespace-per-app and digest pinning ([#24](https://github.com/dackota/generic-app-chart/issues/24))

### Features

* default NetworkPolicy/PDB on, add namespace-per-app and digest pinning ([#24](https://github.com/dackota/generic-app-chart/issues/24)) ([80831d1](https://github.com/dackota/generic-app-chart/commit/80831d1a00eaaad2e779fb8634b10ce9c233946a))

## [1.0.0](https://github.com/dackota/generic-app-chart/compare/v0.5.0...v1.0.0) (2026-07-29)


### ⚠ BREAKING CHANGES

* apps that set `config` and rely on pods restarting when it changes must now set `configChecksumAnnotation: true`. On upgrade such apps see one final rollout as the annotation is dropped from the pod template. No app in free-tier-oracle-cloud-k8s depends on this today: consulting-spa and resume-website set no config, and change-tracking-dashboard hot-reloads its tracker config.

### Features

* gate the config checksum annotation behind a values flag ([#21](https://github.com/dackota/generic-app-chart/issues/21)) ([4252f16](https://github.com/dackota/generic-app-chart/commit/4252f16b3ddab5b06d8eacbc1b422c84405be68c))


### Bug Fixes

* **release-please:** enable auto-merge instead of racing the required check ([#23](https://github.com/dackota/generic-app-chart/issues/23)) ([abbb9a4](https://github.com/dackota/generic-app-chart/commit/abbb9a49341c028b3bbf0f5a0559502d2ec4f037))

## [0.5.0](https://github.com/dackota/generic-app-chart/compare/v0.4.1...v0.5.0) (2026-07-29)


### Features

* **ci:** run the chart test suite on PRs and automerge Renovate updates ([#18](https://github.com/dackota/generic-app-chart/issues/18)) ([25d5e8f](https://github.com/dackota/generic-app-chart/commit/25d5e8f6793db9d4d80efe00bd5a49c01ce9ab9f))

## [0.4.1](https://github.com/dackota/generic-app-chart/compare/v0.4.0...v0.4.1) (2026-07-29)


### Bug Fixes

* **renovate:** stop silent whole-repo aborts on every run ([#16](https://github.com/dackota/generic-app-chart/issues/16)) ([b247a6c](https://github.com/dackota/generic-app-chart/commit/b247a6c1ea3a961ab1a0795196ad607c8905faf1))

## [0.4.0](https://github.com/dackota/generic-app-chart/compare/v0.3.1...v0.4.0) (2026-07-07)


### Features

* R36-R44 production-readiness hardening (7 slices) ([#9](https://github.com/dackota/generic-app-chart/issues/9)) ([9476e2f](https://github.com/dackota/generic-app-chart/commit/9476e2f01c3c7a33505e5e2cbf171c0df6388326))

## [0.3.1](https://github.com/dackota/generic-app-chart/compare/v0.3.0...v0.3.1) (2026-07-07)


### Bug Fixes

* address security review findings on App-token auto-merge ([4760ce0](https://github.com/dackota/generic-app-chart/commit/4760ce0ff2c3bdcda605858f6ceca23210965151))
* fail fast on malformed PRS_JSON instead of silently no-op'ing ([26dfd59](https://github.com/dackota/generic-app-chart/commit/26dfd5909acf4dff85ce57d1a77e797f30e4f5f0))
* **release-please:** auto-merge release PRs via App token instead of GITHUB_TOKEN ([d31af12](https://github.com/dackota/generic-app-chart/commit/d31af1299f59ae30be333e8c1b1a9f4f0b3fc95a))
* **release-please:** auto-merge release PRs via App token instead of GITHUB_TOKEN ([718a810](https://github.com/dackota/generic-app-chart/commit/718a8105101f6e003daaf456a5c1d6ae18a8e668))
* scope App token permissions and guard empty parsed-PR payload ([a5c8e01](https://github.com/dackota/generic-app-chart/commit/a5c8e0172e266f5140417e5c38e18038c175ae80))

## [0.3.0](https://github.com/dackota/generic-app-chart/compare/v0.2.0...v0.3.0) (2026-07-07)


### Features

* chart core, security defaults, and persistence (R1-R20) ([cf16edc](https://github.com/dackota/generic-app-chart/commit/cf16edcbbaf7c65297c80003db539838aa6431d9))
* networking trio + cluster-only mode + HPA/PDB/NetworkPolicy (R21-R27) ([ff79bff](https://github.com/dackota/generic-app-chart/commit/ff79bfffa77dcb90b22b42a270897e3d5a958540))


### Bug Fixes

* **release-please:** disable component-in-tag so release tags match the publish trigger ([2a169ed](https://github.com/dackota/generic-app-chart/commit/2a169ed6842990ea558d0db32f43877642b9fa1f))
* **release-please:** disable component-in-tag so release tags match the publish trigger ([919ff70](https://github.com/dackota/generic-app-chart/commit/919ff70b4c880f33ff942080094605ec45d1c0d4))
* scope ReferenceGrant to the Gateway's cross-namespace Secret read only (ADR 0001) ([d05fda4](https://github.com/dackota/generic-app-chart/commit/d05fda4696a582ad8569875902e3c560d7911e59))
* scope ReferenceGrant to the Gateway's cross-namespace Secret read only (ADR 0001) ([f25624a](https://github.com/dackota/generic-app-chart/commit/f25624a0ef5f2c7a64f69f56fcc4166cc22bae53))
* scope ReferenceGrant to this app's own Service/Secret (R23) ([290f8af](https://github.com/dackota/generic-app-chart/commit/290f8aff51d9bebf106c2fc832e09c7b6f747378))

## [0.2.0](https://github.com/dackota/generic-app-chart/compare/generic-app-chart-v0.1.0...generic-app-chart-v0.2.0) (2026-07-07)


### Features

* chart core, security defaults, and persistence (R1-R20) ([cf16edc](https://github.com/dackota/generic-app-chart/commit/cf16edcbbaf7c65297c80003db539838aa6431d9))
* networking trio + cluster-only mode + HPA/PDB/NetworkPolicy (R21-R27) ([ff79bff](https://github.com/dackota/generic-app-chart/commit/ff79bfffa77dcb90b22b42a270897e3d5a958540))


### Bug Fixes

* scope ReferenceGrant to the Gateway's cross-namespace Secret read only (ADR 0001) ([d05fda4](https://github.com/dackota/generic-app-chart/commit/d05fda4696a582ad8569875902e3c560d7911e59))
* scope ReferenceGrant to the Gateway's cross-namespace Secret read only (ADR 0001) ([f25624a](https://github.com/dackota/generic-app-chart/commit/f25624a0ef5f2c7a64f69f56fcc4166cc22bae53))
* scope ReferenceGrant to this app's own Service/Secret (R23) ([290f8af](https://github.com/dackota/generic-app-chart/commit/290f8aff51d9bebf106c2fc832e09c7b6f747378))
