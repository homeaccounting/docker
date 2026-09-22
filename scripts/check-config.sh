#!/usr/bin/env bash
# Two consistency checks that a broken self-host install would otherwise teach
# us the slow way, via a stranger's bug report.
#
#   1. Every ${VAR} the compose file reads is documented in .env.example.
#      A setting nobody can discover is a setting nobody sets.
#   2. Every {$VAR} the Caddy configs read is actually passed to the caddy
#      container. Caddy substitutes missing variables with an empty string, so
#      the failure is a silently wrong route rather than an error.

set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

fail=0

compose_vars=$(grep -oE '\$\{[A-Z0-9_]+' docker-compose.yaml | sed 's/\${//' | sort -u)
documented=$(grep -oE '^#? *[A-Z0-9_]+=' .env.example | tr -d '# ' | sed 's/=$//' | sort -u)

echo "==> compose variables documented in .env.example"
for v in $compose_vars; do
  if ! grep -qx "$v" <<< "$documented"; then
    echo "::error::\${$v} is used by docker-compose.yaml but absent from .env.example"
    fail=1
  fi
done

echo "==> caddy variables passed to the caddy container"
caddy_vars=$(grep -rhoE '\{\$[A-Z0-9_]+' core product observability --include='*.caddy' --include='Caddyfile' \
             | sed 's/{\$//' | sort -u)
for v in $caddy_vars; do
  if ! grep -qE "^\s*-\s*${v}=" docker-compose.yaml; then
    echo "::error::{\$$v} is read by a Caddy config but never passed to the caddy service"
    fail=1
  fi
done

[ "$fail" -eq 0 ] && echo "==> config is consistent"
exit "$fail"
