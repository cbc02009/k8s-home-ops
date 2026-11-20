#!/bin/sh
# setup-doco-cd.sh -- second bring-up step for the iot-pi doco-cd host.
#
# Target OS: Raspberry Pi OS Lite 64-bit (Debian, arm64). Run ON the Pi as root,
# after first boot. First step is flashing the card with Raspberry Pi Imager and
# its OS-customization settings (hostname, timezone, user, SSH) -- see
# docker/AGENTS.md.
#
#   1. installs Docker CE + the compose plugin from Docker's official apt repo
#      for Debian arm64 (skipped when already present and healthy);
#   2. locates this repo (the script's own checkout, ~/k8s-home-ops, or a fresh
#      shallow clone) and deploys this instance's doco-cd container from
#      docker/iot-pi/00-doco-cd/docker-compose.app.yaml.
#
# Idempotent: safe to re-run; `docker compose up -d` reconciles in place.

set -eu

REPO_URL='https://github.com/cbc02009/k8s-home-ops.git'
FALLBACK_DIR="${HOME:-/root}/k8s-home-ops"
SUPPORTED_CODENAMES='bullseye bookworm trixie'

die() {
    echo "setup-doco-cd: $*" >&2
    exit 1
}

[ "$(id -u)" -eq 0 ] || \
    die 'must run as root (installs packages and manages the docker daemon)'

command -v apt-get >/dev/null 2>&1 || \
    die 'apt-get not found -- this script targets Raspberry Pi OS Lite (Debian)'

# --- sanity-check the OS we are about to install packages on ---------------
# shellcheck disable=SC1091
. /etc/os-release
[ -n "${VERSION_CODENAME:-}" ] || \
    die 'cannot determine the Debian release from /etc/os-release'

case " $SUPPORTED_CODENAMES " in
    *" ${VERSION_CODENAME} "*) ;;
    *) die "unsupported release '${VERSION_CODENAME}' (supported: ${SUPPORTED_CODENAMES})" ;;
esac

ARCH=$(dpkg --print-architecture)
[ "$ARCH" = arm64 ] || \
    die "expected a 64-bit image (arm64), found '${ARCH}' -- reflash Pi OS Lite 64-bit"

echo "Detected Raspberry Pi OS (${PRETTY_NAME:-Debian}), ${ARCH}"

# --- docker ----------------------------------------------------------------
# The doco-cd compose file needs compose v2 (the `docker compose` plugin).
if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    echo "Docker already present: $(docker --version)"
else
    echo 'Installing Docker CE from download.docker.com (Debian arm64 repo)...'
    apt-get update
    apt-get install -y ca-certificates curl git
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc
    echo "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian ${VERSION_CODENAME} stable" \
        > /etc/apt/sources.list.d/docker.list
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        docker-ce docker-ce-cli containerd.io \
        docker-buildx-plugin docker-compose-plugin
    systemctl enable --now docker
    echo "Installed: $(docker --version), $(docker compose version)"
fi

# Let the admin user talk to docker without sudo (applies on next login).
if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != root ]; then
    usermod -aG docker "$SUDO_USER" || true
    echo "Added $SUDO_USER to the docker group (log out and back in for it to apply)"
fi

# --- 1Password service-account token ----------------------------------------
# doco-cd resolves the instance's external_secrets (.doco-cd.yaml - the
# Cloudflare DNS token 01-traefik uses for its Let's Encrypt DNS-01 challenge)
# with a 1Password service-account token file, mounted by
# .doco-cd/docker-compose.app.yaml from the path below. Same service account as
# the truenas instance (/mnt/smoltank/apps/doco-cd/secrets/1pw_token).
TOKEN_FILE=/root/.config/doco-cd/1pw_token
if [ ! -s "$TOKEN_FILE" ]; then
    echo "missing or empty $TOKEN_FILE -- copy the 1Password service-account" >&2
    echo "token file there (same one the truenas instance uses) and re-run" >&2
    exit 1
fi

# --- locate the repo / the doco-cd compose file ----------------------------
SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
APP_DIR="$SCRIPT_DIR"

if [ ! -f "$APP_DIR/00-doco-cd/docker-compose.app.yaml" ]; then
    APP_DIR="$FALLBACK_DIR/docker/iot-pi"
    if [ ! -f "$APP_DIR/00-doco-cd/docker-compose.app.yaml" ]; then
        echo "No checkout found -- cloning $REPO_URL into $FALLBACK_DIR..."
        command -v git >/dev/null 2>&1 || apt-get install -y git
        [ -d "$FALLBACK_DIR/.git" ] || git clone --depth 1 "$REPO_URL" "$FALLBACK_DIR"
    fi
fi

COMPOSE_FILE="$APP_DIR/00-doco-cd/docker-compose.app.yaml"
echo "Deploying doco-cd from $COMPOSE_FILE"

# DEPLOY_CONFIG_BASE_DIR in the compose file is relative to doco-cd's own clone
# of the repo inside its container -- the host checkout is only needed for this
# compose file itself.
docker compose -f "$COMPOSE_FILE" up -d

# --- wait for the container healthcheck ------------------------------------
echo 'Waiting for the doco-cd healthcheck...'
STATE=unknown
i=0
while [ "$i" -lt 12 ]; do
    STATE=$(docker inspect --format '{{.State.Health.Status}}' doco-cd 2>/dev/null || echo unknown)
    if [ "$STATE" = healthy ]; then
        break
    fi
    i=$((i + 1))
    sleep 5
done

if [ "$STATE" != healthy ]; then
    echo "doco-cd is NOT healthy (state: ${STATE}) -- check 'docker logs doco-cd'" >&2
    exit 1
fi

echo 'doco-cd is healthy.'
PI_IP=$(hostname -I 2>/dev/null | awk '{print $1}')
echo
echo 'Done. doco-cd reconciles the stacks in docker/iot-pi/ hourly'
echo '(poll-config.yml, interval 3600s) from the GitHub repo.'
if [ -n "$PI_IP" ]; then
    echo "  UI/health endpoint: http://${PI_IP}:7789"
fi
echo 'Next steps (see docker/AGENTS.md):'
echo '  - plug in the Zigbee/Z-Wave controllers'
echo '  - ls -l /dev/serial/by-id/ and fill the by-id paths into'
echo '    02-zigbee2mqtt and 03-zwave2mqtt (then commit the change)'
echo '  - Cloudflare A records zigbee.cnas.dev / zwave.cnas.dev pointing at the'
echo '    Pi, then the UIs are https://zigbee.cnas.dev and https://zwave.cnas.dev'
