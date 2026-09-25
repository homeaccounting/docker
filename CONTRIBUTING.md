# Contributing to the HomeAccounting stack

This repository is the deployable stack: one compose file, the Caddy edge
config, the Grafana/Loki/Prometheus configs, and the script that assembles the
edge from the active profiles. No application code lives here.

**It is also what runs [homeaccounting.com](https://homeaccounting.com/app).**
The hosted instance adds only its own secrets and provisioning, from a private
repository. That is the point of the repo — the self-host path cannot drift
from production, because it is the same file — and it is the main thing to keep
in mind when changing anything: a change here changes a live deployment.

## Where things go

| Change | Where |
| --- | --- |
| Compose services, images, volumes | `docker-compose.yaml` |
| Public routing (`/api`, `/app`) | `product/caddy/product.caddy` |
| Shared edge behaviour, operator guard | `core/caddy/Caddyfile` |
| Dashboards, scrape configs, log pipeline | `observability/**` |
| New setting | `docker-compose.yaml` **and** `.env.example` |
| Bug in the app itself | [`backend`](https://github.com/homeaccounting/backend) / [`web`](https://github.com/homeaccounting/web) |

**Every new variable must appear in `.env.example`.** CI enforces this: a
variable referenced by the compose file and missing from the example fails the
build. That check exists because a missing variable is invisible to us and
fatal for someone following the README.

## Testing a change

No cluster required:

```bash
./scripts/ci-env.sh             # a throwaway .env, same as CI builds
./scripts/check-config.sh       # compose, Caddy configs and .env.example agree

# every documented profile combination must be a valid project
for p in core core,product,db core,product core,product,db,observability; do
  COMPOSE_PROFILES=$p docker compose config --services
done

./scripts/caddy-assemble.sh core,product,db,observability
```

Use `./scripts/ci-env.sh` rather than filling `.env.example` with a constant:
three of the values are parsed by the API at startup and make it exit if they
are malformed, so dummy values turn "the stack is broken" into "CI filled the
template with nonsense".

CI additionally pulls the images anonymously and boots the stack, which is the
check that a stranger's first five minutes still work.

If you can, run it for real against a spare domain before proposing an edge
change — Caddy configuration errors tend to surface only on a live certificate
request.

## Keep it portable

Anything that assumes our deployment breaks everyone else's. Specifically:

- No hardcoded domains, IPs, or paths — take them from the environment, with a
  default that suits a self-hoster rather than us
- No dependency on our host's filesystem layout
- Defaults should produce a working single-machine install

The apex redirect is the cautionary tale: it pointed at our marketing site, so
following the file would have broken a self-hoster's root. It is now
`ROOT_REDIRECT`, defaulting to the app.

## Commits, branches, pull requests

- [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/):
  `<type>[(scope)]: <description>`
- Branches: `<type>/<short-description>`, based on `master`
- PR titles follow the same convention; say what a self-hoster has to do
  differently as a result of the change

## Contributor Licence Agreement

A first pull request needs a signed
[CLA](https://github.com/homeaccounting/site/blob/master/CLA.md). A bot asks on
the pull request and records the signature; you keep your copyright.

## Code of Conduct

Participation is governed by our [Code of Conduct](CODE_OF_CONDUCT.md). Reports
go to `conduct@homeaccounting.com`.

## Licence

AGPL-3.0. By contributing you agree your work is licensed under it.

## Trademarks

The AGPL covers the code, not the name. Run this stack unmodified and call it
HomeAccounting; publish a **modified** stack, or operate it as a hosted service
for other people, and you must rebrand. Full policy:
<https://www.homeaccounting.com/trademark>.
