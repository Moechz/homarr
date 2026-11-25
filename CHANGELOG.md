# Changelog

All notable user-visible changes to the Homarr TOS application package.

## 2.13.0-3 — 2026-11-25

Remediation of the 2.13.0-2 review findings (C10, C3, C8, C9, T1, F1, V7) and
the related compliance work.

### Compliance

- **C10:** added a complete `README.md` with repository layout, install,
  data/backup/uninstall, privacy, notices, build and verification sections.
  Added `NOTICE.md`; the repository is public.
- **C3/C4/C5:** added `PRIVACY.md` with the data inventory, host paths,
  retention period, user rights, security measures, deletion channel and
  contact. `tosapp.json.help` and `config.ini.help` now point at the public
  policy.
- **C8:** disclosed every third-party endpoint the container, the UI and the
  browser can contact: PostHog analytics, Open-Meteo (forecast, air quality and
  geocoding), jsDelivr and GitHub icon repositories, Docker Hub, Frankfurter,
  mcsrvstat.us and the services configured in widgets, including what is sent
  and the destination. `PRIVACY.md` §6 is the authoritative table.
- **C9:** rewrote the `zh-cn` and `zh-hk` descriptions, which still described a
  different application (a habit tracker). Removed all ASCII semicolons from
  the lang values, refreshed the English description and the release note, and
  removed the stale `probe` / `entrypoint_file` blocks that contained another
  application's image digest and trial-run log.

### Runtime

- **F1 / web interface:** the wrapper entrypoint now reproduces the upstream
  start-up sequence. It runs nginx on port 7575, proxies the UI to Next.js on
  3000 and `/websockets` to 3001, then starts Redis and Next.js. Earlier
  packaging iterations started Next.js directly on 7575 and left the WebSocket
  endpoint unhandled. The data directories and the persistent encryption key
  are still created before the migrations.
- Added `cap_drop: [ALL]` and `no-new-privileges:true`; the container already
  ran as uid 1000.
- Healthcheck `start_period` raised to 120 s and `retries` to 5 so a slow first
  migration on an HDD does not make the install look failed.
- The data directory, database and key are created with `0600`/`0700`
  permissions.

### Integrity

- **V7:** both the package and its published SHA-256 are rebuilt from the same
  commit with the deterministic build, and the platform's recorded `file_hash`
  is compared with the local `sha256sum` after submission.

### Compatibility / T1

- **x86_64 only.** The Docker Hub mirror `moechz/homarr` has a single
  `v2.13.0` tag and it is a single `linux/amd64` manifest. The upstream
  multi-architecture image is published on ghcr.io, which the store does not
  accept, so no aarch64 package is submitted. See `NOTICE.md` §3.
- **T1:** upstream v2.14.0 (2026-11-20) bundles Node.js 24.22.3 with a security
  update, while the pinned 2.13.0 image has Node.js 24.22.2. The mirror has no
  newer tag, so the image cannot be upgraded in this release. Mitigations and
  the follow-up plan are in `NOTICE.md` §5.

## 2.13.0-2 — 2026-11-23

- Store submission that received the review findings C10, C3, C8, C9, T1, F1
  and V7.

## 2.13.0-1 — 2026-11-14

- First release. Homarr (`moechz/homarr:v2.13.0`, Docker Hub image, unmodified)
  packaged as a TOS 7 Docker application on port 8149, running as a non-root
  user (1000:1000).
- Persistent data is kept under `/Volume1/DockerAppData/homarrdocker/`.
