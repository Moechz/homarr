# Privacy Policy — Homarr for TerraMaster TOS (`homarrdocker`)

**Last updated:** 25 November 2026
**Data controller / contact:** Moechz — moechz@163.com
**Applies to:** version `2.13.0-3` and later of the TOS application
`homarrdocker`, the container image it runs and this repository.

## 1. Summary

- Homarr runs **on your NAS**. The developer does not operate a Homarr server,
  does not receive your boards, links, credentials or usage data, and has no
  account system of its own.
- Homarr's upstream code contains **one telemetry feature that is enabled by
  default**: once a day it sends an aggregate usage snapshot to PostHog (see
  §6). It contains an anonymous instance ID and entity counts only — no board
  names, URLs, credentials or user names. You can switch it off in
  **Settings → Analytics → General**.
- Everything else is optional and only happens when you configure the matching
  widget or integration. The endpoints are listed in §6.
- The package adds **no** telemetry and no developer-operated endpoint. It does
  not mount the Docker socket, does not run as root and does not add any
  capability.

## 2. What data is processed and where it is stored

Everything Homarr writes lives in the application data folder
`/Volume1/DockerAppData/homarrdocker/appdata` on your NAS.

| Data | Stored at | Notes |
|---|---|---|
| User accounts: user name, e-mail address (optional), role, bcrypt password hash, group membership | `…/appdata/db/db.sqlite` | created on first start, file mode `0600` |
| Boards, sections, app tiles, links, icons, layout and theme settings | `…/appdata/db/db.sqlite` | the content you create in the UI |
| Widget and integration settings, including the URLs, user names, passwords, API keys and tokens you enter for Sonarr, Radarr, Pi-hole, AdGuard, download clients, Home Assistant and similar services | `…/appdata/db/db.sqlite` | integration secrets are encrypted by Homarr with `SECRET_ENCRYPTION_KEY` |
| `SECRET_ENCRYPTION_KEY` (32 random bytes, hex) | `…/appdata/encryption_key` | generated once on first start, mode `0600`, never leaves the NAS |
| Redis cache and session data | `…/appdata/redis/` | internal Redis instance, persisted as a small dump file |
| Custom trusted certificates | `…/appdata/trusted-certificates/` | only if you add your own CA certificates |
| Logs | stdout/stderr only — `docker logs homarrdocker` | no log file is written to the NAS |

The web UI is served over plain HTTP on port 8149. Session cookies are stored
in your browser. No data is uploaded to the developer or to TerraMaster beyond
what the App Center itself does when it downloads the package and the image.

## 3. Retention period

- **Accounts, boards, links and settings:** kept until **you** delete them.
  There is no automatic expiry.
- **Integration secrets:** kept until you change or remove the integration, or
  delete the database.
- **PostHog usage snapshot:** one aggregate event per day. The last successful
  send time is kept locally in `db.sqlite`. The event itself is retained by
  PostHog according to that service's retention settings (see §6).
- **Logs:** stdout/stderr only. The Docker daemon keeps them according to its
  own rotation settings.
- **Uninstalling** the application from the App Center does **not** delete the
  data folder; see §4 for the deletion steps.

## 4. Your rights and the deletion channel

| Right | How |
|---|---|
| Access / export | Copy `/Volume1/DockerAppData/homarrdocker/appdata/` while the container is stopped. It contains the complete state. Boards can also be exported from the Homarr UI. |
| Correct | Edit users, boards, apps, widgets and integrations in the Homarr UI. |
| Delete | Stop the container, then delete `/Volume1/DockerAppData/homarrdocker/`, or uninstall the app with the App Center's “delete data” option where available. |
| Delete the analytics snapshot | Switch off **Settings → Analytics → General** (no further events are sent) and delete `db.sqlite` if you also want to remove the local instance ID. |
| Assistance | Email **moechz@163.com** with the subject “Homarr data request”; a reply follows within 30 days. |

The developer holds no copy of your data, so deletion is normally completed by
removing the folder on your own NAS. The e-mail channel exists for questions and
for requests concerning the published package.

## 5. Security measures

- The container runs as **uid 1000**, never root, with `cap_drop: [ALL]` and
  `no-new-privileges:true`.
- No `privileged` mode, no host network, and **no Docker socket** is mounted.
  Homarr's optional Docker integration is therefore not enabled by this package.
- Only the application port is published (host `8149` → container `7575`).
- The database and the encryption key are created with mode `0600`; passwords
  are stored as bcrypt hashes, and integration secrets are encrypted with a key
  generated on the NAS.
- The upstream image is pinned to a fixed tag and digest. When upstream ships a
  security rebuild, the package is re-published against it.
- The UI is plain HTTP. If you expose it outside the LAN, put it behind a TLS
  reverse proxy and keep the application updated.

## 6. Third-party sharing and API disclosure (C8)

The developer shares nothing and operates no server. The application, the
container and your browser contact only the endpoints below.

### 6.1 Enabled by default

| Service | Endpoint | Data sent | Destination / region | When |
|---|---|---|---|---|
| PostHog (upstream usage analytics) | `https://us.i.posthog.com` | event `server-analytics`: a random instance UUID and aggregate entity counts (for example number of users, boards, apps and integrations). No board names, URLs, credentials, user names or IP geolocation (`disableGeoip: true`). | PostHog Inc., **United States** | once per day, starting on first start. **Enabled by default** — switch it off in **Settings → Analytics → General**. |
| Icon index refresh | `https://api.github.com/repos/homarr-labs/dashboard-icons/git/trees/main`, `…/selfhst/icons/git/trees/main`, `…/simple-icons/simple-icons/git/trees/master` | plain GitHub API read, no user data beyond the request itself | GitHub, Inc., **United States** | on start and periodically, to build the icon picker |
| Icon images | `https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/…`, `https://cdn.jsdelivr.net/gh/selfhst/icons/…`, `https://cdn.jsdelivr.net/gh/PokeAPI/sprites/…`, `https://cdn.jsdelivr.net/gh/PapirusDevelopmentTeam/…` | your browser's IP address, user agent and the requested icon path | jsDelivr CDN (global, operated from the **EU/US**) | when a board renders an icon |
| Image pull | `registry-1.docker.io` (Docker Hub) or your configured registry mirror | anonymous image pull request | Docker Hub, **United States** | at installation and when the image is updated |

### 6.2 Only when you configure the matching widget or integration

| Service / widget | Endpoint | Data sent | Destination / region |
|---|---|---|---|
| Weather | `https://api.open-meteo.com/v1/forecast` | latitude and longitude you configure | Open-Meteo, **EU** |
| Air quality | `https://air-quality-api.open-meteo.com/v1/air-quality` | latitude and longitude you configure | Open-Meteo, **EU** |
| Location search | `https://geocoding-api.open-meteo.com/v1/search` | the place name you type | Open-Meteo, **EU** |
| Currency / finance | `https://api.frankfurter.dev/v1/latest` | currency codes and amount you configure | Frankfurter, **EU** |
| Minecraft server status | `https://api.mcsrvstat.us/3/<server>` | the server address you configure | mcsrvstat.us, **EU** |
| Docker Hub integration | `https://hub.docker.com` (public repository API) | the repository name you configure | Docker, Inc., **United States** |
| RSS / Atom feeds | the feed URL you configure | a normal HTTP GET from the container | the site you chose |
| Calendar | the iCalendar URL you configure | a normal HTTP GET from the container | the site you chose |
| Releases / notifications | the provider you configure (GitHub, GitLab, Docker Hub, …) | the repository or project identifier you configure | the provider you chose |
| Sonarr, Radarr, Prowlarr, Lidarr, Readarr, qBittorrent, Transmission, Deluge, SABnzbd, NZBGet, Pi-hole, AdGuard Home, Home Assistant, Uptime Kuma, Beszel, Speedtest Tracker, Proxmox, TrueNAS, Unraid, Portainer and similar integrations | the URL and credentials you enter | API requests with your credentials | **your own service**, normally on your LAN |
| AI integrations (OpenAI, Anthropic, Google Gemini, Mistral, Groq, xAI, DeepSeek, OpenRouter, Together and OpenAI-compatible endpoints) | the provider endpoint you configure | the prompt or text you send through the AI feature | the provider you chose |
| Icon/metadata URL entered for an app | the URL you paste, fetched by the container | a normal HTTP GET from the NAS | the site you chose |
| Search bar | the search engine you select (Homarr ships Google, DuckDuckGo, Bing, Wikipedia, YouTube, Spotify, Tidal, Deezer, IMDb, TMDB, Reddit and Homarr Docs as defaults) | the query you type | the search provider you selected, opened by **your browser** |
| Links on your boards | the URLs you add | a normal browser navigation | the site you chose |

Notes:

- The server-side calls in §6.1 and §6.2 are made by the container from your
  NAS, not by the browser, unless the row explicitly says “browser”.
- Set `NO_EXTERNAL_CONNECTION=1` in the container environment to disable the
  server-side external lookups that honour this flag (weather, geocoding, icon
  lookup, icon index refresh and documentation search). Analytics has its own
  setting and is not affected by this flag.
- The developer does **not** run an update check. New package versions are
  delivered through the TerraMaster App Center only.

## 7. What the developer does not do

- No account, newsletter, licence check or activation.
- No crash reports or usage statistics sent to the developer.
- No advertising or tracking pixels in the package.
- No sharing of data with TerraMaster beyond what the App Center itself does
  (downloading the package and the container image).

## 8. Changes to this policy

The policy is versioned with the application in this repository. A material
change is described in `CHANGELOG.md` and in the release notes of the version
that introduces it.

## 9. Contact

Moechz — **moechz@163.com**
Issues and questions: <https://github.com/Moechz/homarr/issues>
Upstream project: <https://github.com/homarr-labs/homarr>
