# Notices — Homarr for TerraMaster TOS (`homarrdocker`)

This repository contains **packaging only**. No upstream source code is
redistributed here: the application is delivered as a Docker Hub image,
unmodified, together with a four-file TOS application archive (`config.ini`,
`homarrdocker.lang`, `homarrdocker.svg`, `docker-compose.yml`).

## 1. Upstream project

| | |
|---|---|
| Project | Homarr — a modern dashboard for self-hosted services |
| Homepage | <https://github.com/homarr-labs/homarr> |
| Authors | Homarr Labs and contributors |
| License | **Apache-2.0** (verified with the GitHub licence API and the upstream `LICENSE`) |
| Version used | **2.13.0** (upstream release 2026-11-13) |

The Apache-2.0 licence permits use, modification and redistribution provided the
licence and attribution notices are retained. They remain in the upstream image
and in this notice.

## 2. Container image

| | |
|---|---|
| Image | `moechz/homarr:v2.13.0` (Docker Hub mirror of the upstream image, used unmodified) |
| Manifest digest | `sha256:2ad74123ba998bfaf18b5d744ecfa202407079b53f5a31741d94ca426a888729` |
| Platform | **`linux/amd64` only** — this tag is a single OCI image manifest, not an index |
| Base | Debian GNU/Linux 13 (trixie) |
| Runtime | Node.js 24.22.2, nginx 1.26.3, Redis 8.8.0 |
| Built | 2026-11-13 (upstream revision `06f05dcbf5cfdb9f378aca4bf70e795ecd5aa924`) |

The image can be verified with:

```bash
docker manifest inspect moechz/homarr:v2.13.0
```

This package never re-tags or rebuilds the image.

## 3. Architecture support (aarch64)

**Only the x86_64 package is built.** The Docker Hub mirror `moechz/homarr` has
exactly one tag (`v2.13.0`) and that tag is a single `linux/amd64` manifest.
Installing it on an aarch64 NAS would fail with `exec format error`, which the
App Center reports as a failed installation. Submitting an aarch64 package that
points at this image would therefore repeat the F1/V10 finding.

The upstream project publishes multi-architecture images
(`linux/amd64` + `linux/arm64`), but only on **ghcr.io**, and the TOS store
accepts Docker Hub images only. Mirroring the arm64 variant to Docker Hub is not
possible from the current build host (Docker Hub push is unreachable), so no
aarch64 package is submitted.

Follow-up plan: if the Docker Hub mirror publishes an arm64 (or multi-arch) tag,
or if the store starts accepting ghcr.io images, a matching aarch64 package is
built and submitted in the same release cycle. This is recorded in
`CHANGELOG.md` and in the release notes.

## 4. Trademarks and affiliation

- “Homarr” and the Homarr logo belong to the upstream project and its authors.
  The application icon in this repository is the upstream Homarr logo, used to
  identify the application.
- “TerraMaster”, “TOS” and “App Center” are trademarks of TerraMaster.
- Docker and Docker Hub are trademarks of Docker, Inc.
- PostHog is a trademark of PostHog, Inc.

This is an **independent community submission** by Moechz. It is not produced,
endorsed or supported by the Homarr upstream project, Homarr Labs or
TerraMaster.

## 5. Third-party components and services inside the image

The container image bundles the upstream Next.js application and its
dependencies. Those libraries remain under their own licences as declared by
the upstream project. The image also contains nginx (BSD-2-Clause), Redis
(RSALv2/SSPLv1 for recent versions, with the image's own notices) and Node.js
(MIT).

At runtime Homarr can contact Open-Meteo, jsDelivr, GitHub, PostHog, Docker Hub,
Frankfurter, mcsrvstat.us and the services you configure in widgets. The full
list, including what is sent and the destination, is in `PRIVACY.md` §6.

### Known vulnerabilities (T1)

The upstream v2.14.0 release notes state that the Docker image bundles a Node.js
security update (Node.js 24.22.3 or later). The pinned 2.13.0 image contains
**Node.js 24.22.2**, which is the component identified by the review's T1 item.
The newer image is not available on Docker Hub (the mirror has only `v2.13.0`),
and the package must keep using a Docker Hub image, so the upgrade cannot be
performed in this release.

Mitigations that do apply and are part of this package:

- The container runs as uid 1000 with `cap_drop: [ALL]` and
  `no-new-privileges:true`; there is no root process, no privileged mode and no
  host network.
- No Docker socket is mounted, so the container cannot control the host daemon.
- Only port 8149 is published; keep the UI on the LAN or behind a TLS reverse
  proxy.
- Homarr authentication is enabled by default (the onboarding wizard creates the
  administrator account).

Follow-up plan: watch the Docker Hub mirror and the upstream releases. As soon
as a Docker Hub tag with Node.js 24.22.3+ (v2.13.1 or v2.14.0) exists, this
package is rebuilt against it, the digest is recorded here and the version is
re-submitted with a remediation note. The check is repeated with every review
cycle and recorded in `CHANGELOG.md`.

## 6. This packaging

Copyright (c) 2026 Moechz. The packaging files (the four-file archive, the build
scripts and the documentation in this repository) are released under the **MIT
licence**, see `LICENSE`.

`TOSAppSelfTestingTool` is an official TerraMaster utility. It is kept in the
source repository for local validation and is **not** part of the application
archive.

## 7. Privacy

The privacy policy for this application — what is stored, what leaves the NAS
and to which third-party endpoints — is in `PRIVACY.md`.
