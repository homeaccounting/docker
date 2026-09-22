#!/usr/bin/env bash
# Pin the application images to a specific tag, so an upgrade is a deliberate
# act rather than whatever `latest` happens to be.
#
#   ./scripts/pin.sh 1a2b3c4     pin both app images
#   ./scripts/pin.sh latest      track the newest build again
#
# Takes effect on the next `./scripts/update.sh`.

set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

TAG="${1:?usage: pin.sh <tag>}"
[ -f .env ] || { echo "error: no .env here — copy .env.example and fill it in" >&2; exit 1; }

sed -i.bak -e "s|^BACKEND_TAG=.*|BACKEND_TAG=${TAG}|" -e "s|^WEB_TAG=.*|WEB_TAG=${TAG}|" .env
rm -f .env.bak

grep -E '^(BACKEND_TAG|WEB_TAG)=' .env | sed 's/^/  /'
echo "==> pinned. apply with: ./scripts/update.sh"
