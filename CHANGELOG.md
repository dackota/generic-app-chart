# Changelog

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
