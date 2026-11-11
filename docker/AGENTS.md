# docker/ — doco-cd-managed compose stacks

Docker Compose apps that [doco-cd](https://github.com/kimdre/doco-cd) reconciles from this
repo onto non-k8s docker hosts, one **instance** per host:

| Instance dir | Host | Notes |
|---|---|---|
| `truenas/` | TrueNAS SCALE box "shana" | Uses the shared `app_ipvlan` network with fixed IPs |
| `zigbee-pi/` | Raspberry Pi with Zigbee + Z-Wave controllers | Plain bridge networking |

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
  instance dir (e.g. `./docker/zigbee-pi/`).

## Secrets

- Secrets are 1Password `op://Homelab/<item>/<field>` references under `external_secrets:`
  in `.doco-cd.yaml`; doco-cd injects them as env vars at deploy time. The host's doco-cd
  container needs `SECRET_PROVIDER: 1password` plus a token file mounted (only the
  `truenas/` instance uses this today).
- Non-secret per-stack env goes in a plain `.env` file inside the stack dir. Never write
  plaintext secrets anywhere (sops-pre-commit forbid-secrets + gitleaks will reject).

## Style

- Compose files: `---` first line, then the `# yaml-language-server: $schema=...compose-spec...`
  line, 2-space indent, LF, no tabs (same yamllint config as the rest of the repo).
- Images are Renovate-managed: tag + digest pin (`image: name:tag@sha256:...`); Renovate
  commits land as `feat/fix/chore(container)`. Don't hand-bump versions it manages.
- `docker/.archive/` is retired stacks — never deploy from it.

## zigbee-pi specifics

- Serial controllers must be mapped by `/dev/serial/by-id/...` paths (never
  `/dev/ttyUSBx` — they drift). After plugging a stick in, `ls -l /dev/serial/by-id/` on
  the Pi and set the `devices:` mapping (`/dev/ttyACM0` for zigbee2mqtt, `/dev/zwave` for
  Z-Wave JS UI) plus zigbee2mqtt's `ZIGBEE2MQTT_CONFIG_SERIAL_PORT`.
- Both bridges use the in-cluster mosquitto broker via its LoadBalancer IP:
  `mqtt://10.6.0.16:1883` (see `kubernetes/apps/home/mosquitto`; currently
  `allow_anonymous true`, so no credentials). Home Assistant autodiscovers over the same
  broker with the `homeassistant` topic prefix.
- zigbee2mqtt is configured entirely through `ZIGBEE2MQTT_CONFIG_*` env (fully declarative).
  Z-Wave JS UI keeps MQTT + serial settings in its `store` volume instead — after first
  bring-up, one-time setup at `http://<pi>:8091` (MQTT host/port, HA discovery on, serial
  `/dev/zwave`).
- Pi host ports: doco-cd 7789, zigbee2mqtt frontend 8080, Z-Wave JS UI 8091. The ZWJS UI
  websocket server (3000) is intentionally not published — HA connects over MQTT.

## Validating

- No flate equivalent for this tree (it only renders Flux trees). CI only lints/secrets-scans it, so run
  `pre-commit run --all-files` before pushing.
