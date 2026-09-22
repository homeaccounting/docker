#!/usr/bin/env bash
# Assemble the Caddy conf.d/ directory from the per-profile edge fragments for
# the active profiles. This is what makes the edge track what is deployed: a
# product-only deploy gets only product/caddy/*.caddy; adding the observability
# profile also brings in observability/caddy/*.caddy.
#
# Idempotent — clears conf.d/ of *.caddy and re-copies. Run by scripts/deploy.sh
# on the host and by `just` locally / in CI.
#
# Usage:
#   scripts/caddy-assemble.sh <profiles-csv> [repo_root] [conf_d_dir]
#     <profiles-csv>: e.g. "core,product" or "core,product,observability"
#     [repo_root]   : where the <profile>/caddy/ dirs live (default: repo root)
#     [conf_d_dir]  : output dir (default: <repo_root>/conf.d)

set -euo pipefail

PROFILES="${1:?usage: caddy-assemble.sh <profiles-csv> [repo_root] [conf_d_dir]}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="${2:-$(cd "$SCRIPT_DIR/.." && pwd)}"
CONFD="${3:-$ROOT/conf.d}"

mkdir -p "$CONFD"
# Only ever manage *.caddy fragments; never touch anything else in the dir.
find "$CONFD" -maxdepth 1 -name '*.caddy' -delete

IFS=',' read -ra parsed <<< "$PROFILES"
for profile in "${parsed[@]}"; do
  frag_dir="$ROOT/${profile}/caddy"
  [ -d "$frag_dir" ] || continue
  # core/caddy holds the base Caddyfile (no .caddy extension), so it contributes
  # no fragment — only product/observability/... do.
  while IFS= read -r -d '' frag; do
    cp "$frag" "$CONFD/"
    echo "  + $(basename "$frag")  (profile: ${profile})"
  done < <(find "$frag_dir" -maxdepth 1 -name '*.caddy' -print0)
done

echo "==> conf.d assembled for profiles: ${PROFILES}"
