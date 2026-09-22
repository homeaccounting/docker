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

- A machine with **Docker** and the Compose plugin
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

./scripts/caddy-assemble.sh core,product   # build the edge config
docker compose up -d
```

Open `https://<your-domain>/app`. The first account you register is a normal
account — there is no separate admin.

The API creates its own database schema on first start, so there is no
migration step to run.

## What runs

| Service    | Profile         | What it does                                        |
| ---------- | --------------- | --------------------------------------------------- |
| `caddy`    | `core`          | TLS edge. Routes `/api` and `/app` on one hostname  |
| `api`      | `product`       | The backend                                          |
| `web`      | `product`       | The single-page app                                  |
| `postgres` | `product`       | Event store and read models                          |
| `prometheus`, `loki`, `promtail`, `grafana` | `observability` | Metrics, logs, dashboards — opt-in |

### Why the edge is not optional

The web image is built with a **same-origin** API base, so the app calls `/api`
on whatever host serves it. Running `web` and `api` on two ports will not work —
something has to put them on one hostname, and that is what `caddy` does here.
If you already run your own reverse proxy, point it at the `web` and `api`
containers and reproduce the routing in `product/caddy/product.caddy`.

## Profiles

`COMPOSE_PROFILES` in `.env` decides what runs. The default is `core,product`.

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
./scripts/caddy-assemble.sh core,product,observability
docker compose up -d
```

Grafana lands at `https://grafana.${INTERNAL_DOMAIN}`, behind an IP allowlist
that is **fail-closed by default** (loopback only). Note that `promtail` mounts
the Docker socket read-only to collect container logs; if that is not
acceptable on your host, leave the observability profile off.

## Updating

```bash
docker compose pull
docker compose up -d
```

Pin `BACKEND_TAG` and `WEB_TAG` in `.env` if you would rather upgrade
deliberately than track `latest`.

## Backups

Your data is in the `postgres_data` volume. It is a finance application — back
it up.

```bash
docker compose exec -T postgres pg_dump -U "$DB_USER" "$DB_NAME" | gzip > backup.sql.gz
```

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
