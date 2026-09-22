# Convenience wrappers. Everything here is a plain docker compose command —
# `just` is optional, the README works without it.
set dotenv-load := true

# List available recipes
help:
    @just --list

# Assemble the edge config for the active profiles, then start the stack
up:
    ./scripts/caddy-assemble.sh "${COMPOSE_PROFILES:-core,product}"
    docker compose up -d

# Stop the stack (volumes are kept)
down:
    docker compose down

# Follow logs, optionally for one service: `just logs api`
logs service="":
    docker compose logs -f {{ service }}

# Apply the current stack: re-assemble the edge, pull images, bring it up
update:
    ./scripts/update.sh

# Restart one service, or all of them: `just restart api`
restart service="":
    docker compose restart {{ service }}

# Dump the database to backup.sql.gz
backup:
    docker compose exec -T postgres pg_dump -U "${DB_USER:-accounting}" "${DB_NAME:-accounting}" | gzip > backup.sql.gz
