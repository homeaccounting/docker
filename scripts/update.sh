#!/usr/bin/env bash
# Update this stack in place: refresh the edge config for whatever profiles are
# active, pull newer images, bring everything up, and reclaim the old layers.
#
# Safe to re-run. Does not touch volumes, so your database survives.
#
#   git pull            # to get a newer stack
#   ./scripts/update.sh # to apply it

set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

[ -f .env ] || { echo "error: no .env here — copy .env.example and fill it in" >&2; exit 1; }

# COMPOSE_PROFILES in .env is the single source of truth for what runs, so the
# edge is assembled from exactly the profiles that are active: turning
# observability off stops the Grafana vhost being served.
profiles=$(grep -E '^COMPOSE_PROFILES=' .env | cut -d= -f2- || true)
profiles=${profiles:-core,product}

echo "==> assembling edge config for: ${profiles}"
./scripts/caddy-assemble.sh "$profiles"

echo "==> pulling images"
docker compose pull

echo "==> starting"
docker compose up -d

echo "==> pruning old images"
docker image prune -f

echo "==> done"
docker compose ps
