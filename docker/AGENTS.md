# docker/ — doco-cd-managed compose stacks

Docker Compose apps that [doco-cd](https://github.com/kimdre/doco-cd) reconciles from this
repo onto non-k8s docker hosts, one **instance** per host:

| Instance dir | Host | Notes |
|---|---|---|
| `truenas/` | TrueNAS SCALE box "shana" | Uses the shared `app_ipvlan` network with fixed IPs |
| `iot-pi/` | Raspberry Pi "iot-pi" with Zigbee + Z-Wave controllers | Plain bridge networking; `00-traefik` publishes 80/443 for *.cnas.dev |

## How an instance works

- `<instance>/.doco-cd.yaml` is the instance config: `working_dir`, `auto_discover` at
  `depth: 1` (each subdir with a compose file is a stack; the `NN-` prefix sets deploy
  order), and optional `external_secrets`.
- `auto_discover_opts.delete: true` — **removing a stack dir from git removes it on the
  host** on the next sync. Same caution as Flux's `prune: true`: keep dir names stable.
- `<instance>/.doco-cd/docker-compose.app.yaml` runs doco-cd itself and is **not managed by
  doco-cd** (it can't manage itself): deploy it manually on the host (TrueNAS UI app /
  `docker compose up -d` on the Pi). After editing it, redeploy it yourself. It polls the
  GitHub repo (repo is public; the poll config needs no token) and reconciles stacks.
- doco-cd clones the repo into its `/data` volume; `DEPLOY_CONFIG_BASE_DIR` selects the
  instance dir (e.g. `./docker/iot-pi/`).

## Secrets

- Secrets are 1Password `op://Homelab/<item>/<field>` references under `external_secrets:`
  in `.doco-cd.yaml`; doco-cd injects them as env vars at deploy time. The host's doco-cd
  container needs `SECRET_PROVIDER: 1password` plus a token file mounted (both instances
  use it; the Pi's file is `/root/.config/doco-cd/1pw_token`, preflighted by
  `setup-doco-cd.sh`).
- Non-secret per-stack env goes in a plain `.env` file inside the stack dir. Never write
  plaintext secrets anywhere (sops-pre-commit forbid-secrets + gitleaks will reject).

## Style

- Compose files: `---` first line, then the `# yaml-language-server: $schema=...compose-spec...`
  line, 2-space indent, LF, no tabs (same yamllint config as the rest of the repo).
- Images are Renovate-managed: tag + digest pin (`image: name:tag@sha256:...`); Renovate
  commits land as `feat/fix/chore(container)`. Don't hand-bump versions it manages.
- `docker/.archive/` is retired stacks — never deploy from it.

## iot-pi specifics

- Brings the Pi up in two steps: flash the microSD with **Raspberry Pi OS Lite
  64-bit** (Raspberry Pi Imager; use its OS-customization step for hostname
  `iot-pi` (previously `zigbee-pi.ctec.internal`), timezone `America/New_York`, an
  admin user, and
  SSH enabled); then `setup-doco-cd.sh` (POSIX sh, run **on the Pi**, as root,
  after first boot — from a repo clone or standalone; when run standalone it
  clones the repo to `~/k8s-home-ops`) installs Docker CE + the compose plugin
  from Docker's official Debian arm64 apt repo if missing and deploys this
  instance's doco-cd container from the repo's `.doco-cd/docker-compose.app.yaml`
  (the script first preflights the 1Password service-account token file at
  `/root/.config/doco-cd/1pw_token` - the doco-cd container mounts it to resolve the
  instance's `external_secrets`; same service account as the truenas box).
- **00-traefik**: the instance's reverse proxy. It deploys first (the 00- prefix)
  because it creates the shared `app` bridge network that the other stacks attach to
  (declared `external: true` in their own files) - that is how traefik's docker
  provider reaches the workloads by container name. Serves `zigbee.cnas.dev`
  (zigbee2mqtt) and `zwave.cnas.dev` (Z-Wave JS UI) over HTTPS: 80 to 443 redirect,
  Let's Encrypt via a Cloudflare DNS-01 challenge (a `*.cnas.dev` wildcard), the CF
  API token coming from the instance `external_secrets` (same 1Password item as
  `truenas/`). Static config in `config/traefik.yaml`; `config/dynamic/` is the
  file-provider dir for future routers (no dashboard router on purpose -
  `traefik.cnas.dev` belongs to the truenas box). Bring-up prerequisites: the
  1Password token file above and Cloudflare A records for zigbee.cnas.dev /
  zwave.cnas.dev pointing at the Pi.
- Serial controllers must be mapped by `/dev/serial/by-id/...` paths (never
  `/dev/ttyUSBx` — they drift). After plugging a stick in, `ls -l /dev/serial/by-id/` on
  the Pi and set the `devices:` mapping (`/dev/ttyACM0` for zigbee2mqtt, `/dev/zwave` for
  Z-Wave JS UI) plus zigbee2mqtt's `ZIGBEE2MQTT_CONFIG_SERIAL_PORT`.
- Both bridges use the in-cluster mosquitto broker via its LoadBalancer IP:
  `mqtt://10.6.0.16:1883` (see `kubernetes/apps/home/mosquitto`; currently
  `allow_anonymous true`, so no credentials). Home Assistant autodiscovers over the same
  broker with the `homeassistant` topic prefix.
- zigbee2mqtt is configured entirely through `ZIGBEE2MQTT_CONFIG_*` env (fully declarative).
  Z-Wave JS UI is repo-driven for serial + driver settings: `ZWAVE_PORT` forces the
  controller on at `/dev/zwave`, and the read-only `02-zwave2mqtt/external-settings.json`
  (mounted in the container) is merged over the store at startup and hides those controls
  in the web UI — it pins logging, RF region (1 = USA), soft reset, statistics off and
  the WS server off. Still one-time UI after first bring-up, at `https://zwave.cnas.dev`
  (or `http://<pi>:8091`): MQTT
  host/port + HA discovery, and the S0/S2 security keys — secrets can't be committed and
  11.26.2 has no env-var path for keys.
- Pi host ports: doco-cd 7789, traefik 80/443, zigbee2mqtt frontend 8080, Z-Wave JS UI
  8091 (the latter two are also served as zigbee.cnas.dev / zwave.cnas.dev). The ZWJS UI
  websocket server (3000) is intentionally not published — HA connects over MQTT.

## Validating

- No flate equivalent for this tree (it only renders Flux trees). CI only lints/secrets-scans it, so run
  `pre-commit run --all-files` before pushing.
