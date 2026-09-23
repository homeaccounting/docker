#!/usr/bin/env bash
# Produce a throwaway .env for CI from the template.
#
# Most values can be any string, but three are parsed by the API at startup and
# make it exit if they are malformed — BANKING_TOKEN_ENC_KEY in particular must
# be exactly 32 base64 bytes. Generating them properly is what lets CI tell
# "the stack is broken" apart from "CI filled the template with nonsense".

set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

sed -E 's/^([A-Z0-9_]+)=$/\1=ci-placeholder/' .env.example > .env

set_var() {
  sed -i.bak -E "s|^$1=.*|$1=$2|" .env && rm -f .env.bak
}

set_var DB_PASSWORD "$(openssl rand -hex 16)"
set_var JWT_SECRET "$(openssl rand -hex 32)"
set_var BANKING_TOKEN_ENC_KEY "$(openssl rand -base64 32)"
set_var GRAFANA_ADMIN_PASSWORD "$(openssl rand -hex 16)"
set_var INTERNAL_DOMAIN ops.example.com

echo "==> .env written for CI"
