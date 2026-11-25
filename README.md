# homarr-for-tos

> TerraMaster TOS 7 App Center — **Docker application** package for
> [Homarr](https://github.com/homarr-labs/homarr).

## What this is

A four-file TOS Docker application archive (`homarrdocker.tar.gz`) that installs
Homarr on TOS 7 through the App Center:

- `config.ini` — TOS application metadata (`application_type: docker`, id `homarrdocker`)
- `homarrdocker.lang` — 23-language superset (TOS requires 14)
- `homarrdocker.svg` — application icon (1655 bytes, 4 SVG elements)
- `docker-compose.yml` — one service, image `moechz/homarr:v2.13.0`

The package runs the upstream image unmodified. It is **x86_64 only** because
the Docker Hub mirror is a single `linux/amd64` manifest; see
[Architecture support](#architecture-support).

## How it works

| | |
|---|---|
| Container image | `moechz/homarr:v2.13.0` (Docker Hub, used unmodified) |
| Open | `http://<NAS-IP>:8149/` (container port 7575) |
| Runs as | non-root, `user: "1000:1000"`, `cap_drop: [ALL]`, `no-new-privileges` |
| Persistent data | `/appdata` → `/Volume1/DockerAppData/homarrdocker/appdata` |
| Database | SQLite at `…/appdata/db/db.sqlite` |
| Logs | `docker logs homarrdocker` (stdout/stderr) |

On start the wrapper entrypoint creates the data directories and a persistent
`SECRET_ENCRYPTION_KEY`, runs the SQLite migrations, then starts nginx on 7575
(proxying the UI to Next.js on 3000 and `/websockets` to 3001), Redis and the
Next.js server. This mirrors the upstream image entrypoint without ever running
as root: the TOS installer chowns the mounted data folder to uid 1000.

## Repository layout

| Path | Purpose |
|---|---|
| `src/config.ini` | App Center metadata, version/platform placeholders |
| `src/homarrdocker.lang` | 23-language description (`tosdocker lang` renders it from `tosapp.json`) |
| `src/homarrdocker.svg` | Store icon |
| `src/docker-compose.yml` | Single-service compose file, `x-app-meta` last |
| `src/entrypoint.sh` | Wrapper entrypoint embedded into the compose file at build time |
| `tosapp.json` | Build spec: image, ports, volumes, translations, release notes |
| `tools/verify.py` | Review-standards self-check (run by `scripts/build.sh`) |
| `scripts/build.sh` | Build one architecture into `out/homarrdocker.tar.gz` + `.sha256` |
| `scripts/build-dual.sh` | Build both architectures (kept for future arm64 support) |
| `test/install-and-verify.sh` | On-device E2E helper (needs root, never used by CI) |
| `TOSAppSelfTestingTool` | Official TerraMaster package checker (not shipped in the archive) |
| `PRIVACY.md` | Privacy policy, data inventory and third-party API disclosure |
| `NOTICE.md` | Upstream licence, image digest, architecture and CVE notes |
| `CHANGELOG.md` | User-visible changes per package version |
| `LICENSE` | MIT licence for this packaging plus third-party notices |

Everything the application writes on the NAS lives inside its own data
directory; the container-internal `/tmp` is discarded with the container.

| Path | Purpose | Created when | Lifecycle |
|---|---|---|---|
| `/Volume1/DockerAppData/homarrdocker/appdata` | Homarr data: SQLite database, encryption key, Redis dump, trusted certificates | on first start | persistent; kept on uninstall unless you ask to delete it |

## Install and first start

1. Install **Homarr** from the App Center (x86_64 NAS only).
2. Open `http://<NAS-IP>:8149/` and complete the onboarding wizard: create the
   administrator account, choose a board layout and add your first apps.
3. Optional: disable **Settings → Analytics → General** if you do not want the
   daily aggregate usage snapshot sent to PostHog (see `PRIVACY.md` §6).

No Docker socket is mounted. The optional Docker integration therefore needs a
reachable Docker API endpoint that you configure yourself; this package does not
grant access to the host daemon.

## Data, backup and uninstall

- **Backup:** stop the container, copy
  `/Volume1/DockerAppData/homarrdocker/appdata/` (the SQLite database, the
  encryption key and the Redis dump are all inside it).
- **Restore:** stop the container, put the folder back and start it again. Keep
  `encryption_key` with the database, otherwise encrypted integration secrets
  cannot be decrypted.
- **Uninstall:** removing the app from the App Center does not delete the data
  folder. To remove everything, stop the app and delete
  `/Volume1/DockerAppData/homarrdocker/`, or use the App Center's “delete data”
  option where available. See `PRIVACY.md` §4.

## Privacy

Homarr stores its data locally and has no developer-operated backend. The
upstream application nevertheless contacts a number of third-party services,
including a **daily PostHog usage snapshot that is enabled by default**, the
Open-Meteo weather/geocoding APIs, jsDelivr and GitHub for icons, Docker Hub, and
whatever widgets you configure (Sonarr, Radarr, Pi-hole, RSS, calendars, AI
providers and so on).

The complete list — endpoint, data sent, destination and when it is called — is
in **[PRIVACY.md](PRIVACY.md)** §6. Set `NO_EXTERNAL_CONNECTION=1` in the
container environment to disable the external lookups that honour that flag.

## Notices and licences

Homarr is **Apache-2.0**, © Homarr Labs and contributors. The container image is
the Docker Hub mirror `moechz/homarr:v2.13.0` (manifest
`sha256:2ad74123ba998bfaf18b5d744ecfa202407079b53f5a31741d94ca426a888729`,
`linux/amd64`), used unmodified. This packaging is MIT, © 2026 Moechz.

Full attribution, the image digest, the architecture gap and the CVE follow-up
are in **[NOTICE.md](NOTICE.md)**. This is an independent community package, not
affiliated with the upstream project or TerraMaster.

## Architecture support

**x86_64 only.** The Docker Hub repository `moechz/homarr` has a single tag
(`v2.13.0`) and it is a single `linux/amd64` OCI manifest. The upstream project
publishes `linux/amd64` and `linux/arm64` images only on `ghcr.io`, and the TOS
store accepts Docker Hub images only, so there is no arm64 image this package
can reference. An aarch64 package would fail with `exec format error` (F1/V10),
so it is not submitted.

Evidence:

```bash
# Docker Hub tags for the mirror
curl -s https://docker.1panel.live/v2/moechz/homarr/tags/list
# {"name":"moechz/homarr","tags":["v2.13.0"]}

# The tag is a single manifest, not an index
curl -sI -H 'Accept: application/vnd.oci.image.manifest.v1+json' \
  https://docker.1panel.live/v2/moechz/homarr/manifests/v2.13.0
# content-type: application/vnd.oci.image.manifest.v1+json
# docker-content-digest: sha256:2ad74123…a888729
```

Follow-up: if the mirror publishes an arm64 or multi-arch tag, or the store
accepts ghcr.io, build and submit the aarch64 package in the same cycle.

## Build

```bash
scripts/build.sh 2.13.0-3 x86_64        # -> out/homarrdocker.tar.gz + .sha256
scripts/build.sh 2.13.0-3 aarch64       # only once an arm64 image exists
scripts/build-dual.sh 2.13.0-3          # both, with the official check per package
```

The build stages the four files, substitutes the version/platform placeholders,
embeds `src/entrypoint.sh` into the compose file (escaping every `$` as `$$`),
removes CRLF/BOM/AppleDouble, then runs `tools/verify.py`: archive layout, JSON
validity, required fields, 14+ language coverage, version consistency,
Docker-Hub-only images, fixed tag, reserved/recommended host ports, non-root
user, per-service healthcheck/TZ/restart, data path below the application data
root, never the `/Volume*` wildcard, comment-free sequence blocks, `x-app-meta`
position, no literal secrets and the SVG size/element limits.

The tarball is deterministic: GNU tar with uid/gid 0 and zeroed timestamps,
gzip without a timestamp. Rebuilding the same commit and version therefore
produces the same SHA-256, which is what the store's integrity check compares.

## Verification

```bash
./TOSAppSelfTestingTool -c out/homarrdocker.tar.gz   # official spec check
python3 ../stage.py . --timeout 300                  # isolated runtime check
```

`stage.py` starts the package with a temporary data directory and a temporary
port, asserts `running` + `healthy`, an HTTP response on the web port and
`user=1000:1000`, then removes everything. It never touches
`/Volume1/DockerAppData/homarrdocker`.

> Docker applications cannot be side-loaded through the App Center's manual
> install page (it accepts `.deb` only).

## Store submission checklist

1. Public GitHub repo (packaging + documentation).
2. Release tag `v2.13.0-3`, assets `homarrdocker.tar.gz` +
   `homarrdocker.tar.gz.sha256`.
3. Developer platform → Add Application: ID `homarrdocker`, package type
   Docker, repository URL, architecture `x86_64`.
4. Version Management → Add Version `2.13.0-3` → automated validation → review,
   with the remark “Rectified per review comments”.

## Known issues and follow-up (T1)

The upstream v2.14.0 release notes mention a Node.js security update (24.22.3 or
later). The pinned 2.13.0 image bundles Node.js **24.22.2**. The Docker Hub
mirror has no newer tag, and the store only accepts Docker Hub images, so this
release cannot upgrade the affected component. The mitigations above (non-root,
`cap_drop: [ALL]`, `no-new-privileges`, no Docker socket, LAN-only by default)
reduce the exposure. A rebuild against v2.13.1/v2.14.0 will be submitted as soon
as the mirror publishes one; see `NOTICE.md` §5.

## Limitations

- x86_64 only, for the reason described above.
- The UI is plain HTTP; use a TLS reverse proxy before exposing it to the
  internet.
- The optional Docker integration is not enabled by this package (no socket).
- Several widgets depend on third-party services that may be unavailable in
  your network; they can be removed from the board.

## Licence

This packaging is MIT, © 2026 Moechz. Homarr itself is Apache-2.0. See
`LICENSE` and `NOTICE.md`.

---

Packaged for TOS 7 by Moechz.
