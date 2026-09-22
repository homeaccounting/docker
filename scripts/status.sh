#!/usr/bin/env bash
# What this instance is currently running: which revision of the stack, which
# image tags, which profiles, and the state of the containers.

set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

echo "==> stack revision"
git log --oneline -1 2>/dev/null || echo "  (not a git checkout)"

echo "==> configuration"
if [ -f .env ]; then
  grep -E '^(COMPOSE_PROFILES|BACKEND_TAG|WEB_TAG|PUBLIC_DOMAIN)=' .env | sed 's/^/  /'
else
  echo "  (no .env)"
fi

echo "==> containers"
docker compose ps
