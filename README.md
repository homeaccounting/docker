# HomeAccounting — the deployable stack

Everything needed to run [HomeAccounting](https://www.homeaccounting.com) on your
own machine: the API, the web app, PostgreSQL, a TLS edge, and optional
dashboards.

This is not a self-host-flavoured copy of something else. **It is the same
compose file, Caddy config and dashboards that run
[homeaccounting.com](https://homeaccounting.com/app)** — the hosted instance
adds only its own secrets and its provisioning, which live in a private repo.
If it works here, it works there, because it is the same file.

## What you need

- An **x86-64** machine with **Docker** and the Compose plugin. The published
  images are `linux/amd64` only for now, so arm64 hosts — Apple Silicon,
  Raspberry Pi, Hetzner CAX, Graviton, Ampere — cannot run them yet without
  emulation (`DOCKER_DEFAULT_PLATFORM=linux/amd64`, which is slow)
- [**`just`**](https://github.com/casey/just) — the commands below are its
  recipes; `just --list` shows them all
- A **domain** with an A/AAAA record pointing at that machine
- Ports **80** and **443** reachable — Caddy obtains and renews the TLS
  certificate itself

## Quickstart

```bash
git clone https://github.com/homeaccounting/docker.git homeaccounting
cd homeaccounting

cp .env.example .env
# Fill in the four REQUIRED values (domain, DB password, JWT secret,
# banking token key). Each one has the command to generate it beside it.

just up          # assemble the edge config, then start the stack
```

Open `https://<your-domain>/app`. The first account you register is a normal
account — there is no separate admin.

The API creates its own database schema on first start, so there is no
migration step to run.

### The recipes

`just` reads `.env` and runs everything from there. `just --list` prints this
same table:

| Recipe | Does |
| ------ | ---- |
| `just` / `just help` | List the recipes |
| `just up` | Assemble the edge config for `COMPOSE_PROFILES`, then start the stack |
| `just down` | Stop the stack (volumes are kept) |
| `just update` | Re-assemble the edge, pull images, bring it up |
| `just status` | What this instance is running: revision, tags, profiles, containers |
| `just pin <tag>` | Pin both app images to a tag |
| `just restart [service]` | Restart one service, or all of them |
| `just logs [service]` | Follow logs, optionally for one service |
| `just backup` | Dump the database to `backup.sql.gz` |

## What runs

| Service    | Profile         | What it does                                        |
| ---------- | --------------- | --------------------------------------------------- |
| `caddy`    | `core`          | TLS edge. Routes `/api` and `/app` on one hostname  |
| `api`      | `product`       | The backend                                          |
| `web`      | `product`       | The single-page app                                  |
| `postgres` | `db`            | Event store and read models — or bring your own      |
| `prometheus`, `loki`, `promtail`, `grafana` | `observability` | Metrics, logs, dashboards — opt-in |

### What is in the checkout

```
docker-compose.yaml         every service, each tagged with a profile
.env.example                every setting there is — copy it to .env
core/caddy/Caddyfile        shared edge: TLS, the operator IP guard
product/caddy/*.caddy       public routing: /api -> api, /app -> web
observability/              prometheus, loki, promtail, grafana + dashboards
conf.d/                     GENERATED — the edge fragments for your profiles
scripts/
  caddy-assemble.sh         builds conf.d/ from the active profiles
  update.sh                 what `just update` runs
  status.sh  pin.sh         what `just status` / `just pin` run
  check-config.sh           CI: compose, the Caddy configs and .env.example agree
  ci-env.sh                 CI: a throwaway .env with well-formed values
justfile                    the recipes above
```

`conf.d/` is rebuilt on every `just up` / `just update` and is gitignored.
Nothing else in the checkout is generated, and nothing needs editing except
`.env`.

### Why the edge is not optional

The web image is built with a **same-origin** API base, so the app calls `/api`
on whatever host serves it. Running `web` and `api` on two ports will not work —
something has to put them on one hostname, and that is what `caddy` does here.
If you already run your own reverse proxy, point it at the `web` and `api`
containers and reproduce the routing in `product/caddy/product.caddy`.

### Behind an existing proxy

If a cloud load balancer, a CDN or your own reverse proxy terminates TLS in
front of this stack, tell Caddy which peers may speak for the client:

```bash
# .env
TRUSTED_PROXIES=10.0.0.0/8        # space-separated CIDRs of those proxies
```

Without it every request appears to come from the proxy, which silently breaks
the operator IP allowlist on `*.${INTERNAL_DOMAIN}`. The default is a
documentation CIDR that matches nothing, so a directly-exposed stack — the
normal case — needs no setting and trusts no inbound `X-Forwarded-For`.

## Profiles

`COMPOSE_PROFILES` in `.env` decides what runs. The default is
`core,product,db`.

### Using a managed database

Drop `db` and point the stack at an external Postgres. Nothing else changes —
the API creates its own schema there on first start.

```bash
# .env
COMPOSE_PROFILES=core,product
DB_HOST=db.internal.example.com
DB_PORT=5432
DB_USER=accounting
DB_PASSWORD=...
DB_NAME=accounting
```

`just backup` expects the bundled container, so use your provider's backups
(or plain `pg_dump`) instead.

To add dashboards (Grafana, Prometheus, Loki):

```bash
# .env
COMPOSE_PROFILES=core,product,observability
INTERNAL_DOMAIN=ops.example.com        # A record pointing at this host
INTERNAL_ALLOW_IPS=203.0.113.4/32      # who may reach it; everyone else gets 403
GRAFANA_ADMIN_PASSWORD=...             # openssl rand -base64 24
```

then re-assemble and bring it up:

```bash
just up          # it reads COMPOSE_PROFILES from .env
```

Grafana lands at `https://grafana.${INTERNAL_DOMAIN}`, behind an IP allowlist
that is **fail-closed by default** (loopback only). Note that `promtail` mounts
the Docker socket read-only to collect container logs; if that is not
acceptable on your host, leave the observability profile off.

## Configuration

`.env` is the only file you edit. Every setting the stack reads is listed and
explained in [`.env.example`](.env.example), and CI fails if the compose file
ever reads a variable that is not documented there — so the template is the
complete list, not a sample of it.

### Keeping `.env` out of the clear

It holds the database password, the JWT secret and `BANKING_TOKEN_ENC_KEY`, so
the file itself is the thing worth protecting:

- It is gitignored here. If you keep your own fork or a config repo, keep it
  that way — `git add -f` defeats the ignore silently, which is why CI also
  fails on any tracked `.env`.
- `chmod 600 .env`. Compose reads it as the invoking user; nothing else needs
  to.
- If you would rather not have a plaintext copy at rest, keep the values in a
  secret store and render the file at deploy time. With
  [sops](https://github.com/getsops/sops) that is an encrypted YAML file in
  your own repository and `sops -d --output-type dotenv secrets.yaml > .env`
  before `just update`. Any store works — the stack only ever reads `.env`.
- `BANKING_TOKEN_ENC_KEY` cannot be rotated once banking is in use: it decrypts
  stored bank tokens, so changing it makes them unreadable. Treat a leak of
  that one value as needing a re-encryption migration rather than a new key.

## Updating

```bash
git pull         # a newer stack (compose, edge config, dashboards)
just update      # apply it: re-assemble the edge, pull images, bring up
```

`just update` is safe to re-run and never touches volumes. It re-assembles the
edge config from whatever `COMPOSE_PROFILES` currently says, so turning
observability off actually stops the Grafana vhost being served.

To upgrade deliberately rather than track `latest`:

```bash
just pin 1a2b3c4     # pin both app images to a tag
just update          # apply it
just status          # revision, tags, profiles, container state
```

This is exactly how [homeaccounting.com](https://homeaccounting.com/app) is
deployed — a checkout of this repository on the host, a `.env` beside it, and
`git pull && just update`. There is no separate production deploy path.

## Backups

Your data is in the `postgres_data` volume. It is a finance application — back
it up.

```bash
just backup      # writes backup.sql.gz
```

That file is a plaintext dump of every transaction in the instance. It is
gitignored here — keep it that way, and move it somewhere off this machine.

Restore into a fresh stack with `gunzip -c backup.sql.gz | docker compose exec -T postgres psql -U "$DB_USER" "$DB_NAME"`.

## Optional features

All off unless configured, all in `.env`:

- **OAuth sign-in** (Google, GitHub, Microsoft) — register
  `${APP_BASE_URL}/app/auth/oauth/<provider>/callback` with each provider
- **Telegram capture** — text a bot and it records transactions; create the bot
  with [@BotFather](https://t.me/BotFather)
- **Natural-language entry** — "coffee 45, taxi 200" becomes transactions. Calls
  an external OpenAI-compatible endpoint (a free Groq key works); nothing is
  self-hosted, and it stays off until you set `LLM_ENABLED=true`

## Help and reporting

- Questions: [the community](https://www.homeaccounting.com/community) — Discord,
  Telegram, and GitHub Discussions
- Bugs in the stack itself: issues on this repository
- Bugs in the application: [`backend`](https://github.com/homeaccounting/backend)
  or [`web`](https://github.com/homeaccounting/web)
- **Security**: please do not open a public issue — see the
  [security policy](https://github.com/homeaccounting/backend/blob/master/SECURITY.md)

## Licence

AGPL-3.0, like the rest of HomeAccounting. See [LICENSE](LICENSE).
