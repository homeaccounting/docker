# The entry point for operating the stack — the README documents these recipes.
# Each one is a plain docker compose command or a script in scripts/, so you can
# always read what it does and run it by hand.
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

# What this instance is running: revision, tags, profiles, containers
status:
    ./scripts/status.sh

# Pin the app images to a tag: `just pin 1a2b3c4` (then `just update`)
pin tag:
    ./scripts/pin.sh {{ tag }}

# Dump the database to backup.sql.gz
backup:
    docker compose exec -T postgres pg_dump -U "${DB_USER:-accounting}" "${DB_NAME:-accounting}" | gzip > backup.sql.gz
