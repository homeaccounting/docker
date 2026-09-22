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

# .gitleaks.toml allowlists .env.example so the secret scanner does not flag
# its empty placeholders. That allowlist is only safe while they stay empty —
# a real value pasted here would ship to a public repo unnoticed.
echo "==> the env template carries no real values"
secretish='^(DB_PASSWORD|JWT_SECRET|BANKING_TOKEN_ENC_KEY|GRAFANA_ADMIN_PASSWORD|LLM_API_KEY|TELEGRAM_BOT_TOKEN|[A-Z]+_CLIENT_ID|[A-Z]+_CLIENT_SECRET)='
while IFS= read -r line; do
  key=${line%%=*}
  value=${line#*=}
  if [ -n "$value" ]; then
    echo "::error::.env.example sets a value for ${key}; sensitive keys must stay empty"
    fail=1
  fi
done < <(grep -E "$secretish" .env.example || true)

[ "$fail" -eq 0 ] && echo "==> config is consistent"
exit "$fail"
