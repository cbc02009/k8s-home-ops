#!/usr/bin/env sh
# One-shot bootstrap: creates the doco-cd stack from this repository and exits. Afterwards Doco-CD
# manages (and updates) its own stack like any other. Run as root on the NAS, once, from a checkout:
#
#   SECRET_PROVIDER_CONNECT_HOST=<connect url> sh docker/system/doco-cd/bootstrap.sh
#
# The image is read from compose.yaml next to this script, so there is nothing to keep in step.
set -eu

DIR="$(cd "$(dirname "$0")" && pwd)"
SECRETS=/mnt/smoltank/apps/doco-cd/secrets
IMAGE="$(sed -n 's/^[[:space:]]*image:[[:space:]]*//p' "$DIR/.doco-cd/docker-compose.app.yaml" | head -n1)"
REPO_URL="https://github.com/cbc02009/k8s-home-ops.git"

: "${SECRET_PROVIDER_CONNECT_HOST:?set SECRET_PROVIDER_CONNECT_HOST}"
for f in connect_token; do
  [ -s "$SECRETS/$f" ] || { echo "missing or empty: $SECRETS/$f" >&2; exit 1; }
done
[ -z "$(docker ps -q --filter publish=8880)" ] || { echo "port 6584 is in use: stop the TrueNAS doco-cd app first" >&2; exit 1; }

# The bootstrap deploys every stack in .doco-cd.yaml (adopting the running projects by name), so it
# needs the same secret provider and token files as the long-running instance.
docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /mnt/smoltank/apps/doco-cd:/data \
  -v "$SECRETS/connect_token":/run/secrets/connect_token:ro \
  -e TZ=America/New_York \
  -e SELF_UPDATE_ENABLED=true \
  -e SELF_UPDATE_STRATEGY=applier \
  -e DEPLOY_CONFIG_BASE_DIR="./docker/truenas/" \
  -e SECRET_PROVIDER=1password \
  -e SECRET_PROVIDER_CONNECT_HOST="$SECRET_PROVIDER_CONNECT_HOST" \
  -e SECRET_PROVIDER_CONNECT_TOKEN_FILE=/run/secrets/connect_token \
  -e POLL_CONFIG="- url: $REPO_URL
  reference: main
  interval: 180" \
  "$IMAGE" apply-self --bootstrap
