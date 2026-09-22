# Security Policy

This repository holds the **deployment stack** for HomeAccounting — the compose
file, the Caddy edge configuration, and the observability configs. It contains
no application code. Vulnerabilities in the product itself belong in
[`backend`](https://github.com/homeaccounting/backend) or
[`web`](https://github.com/homeaccounting/web); the canonical policy for every
repository is
[backend/SECURITY.md](https://github.com/homeaccounting/backend/blob/master/SECURITY.md).

## Reporting a vulnerability

**Please do not open a public issue for security problems.**

- **GitHub Private Vulnerability Reporting** — the **“Report a vulnerability”**
  button under this repository’s **Security** tab (preferred).
- **Email** — `security@homeaccounting.com`.

Machine-readable contact:
[`/.well-known/security.txt`](https://www.homeaccounting.com/.well-known/security.txt).

## What to expect

**Acknowledgement within 3 business days**, an initial assessment within **7**,
and **coordinated disclosure** with a 90-day target.

## Scope for this repository

A finding here is a configuration that makes a correctly-followed installation
insecure. Most relevant:

- **Edge routing** in `product/caddy/product.caddy` — anything that exposes an
  internal path, bypasses `internal_guard`, or lets `/api` be reached in a way
  the app does not expect.
- **The operator allowlist** — `internal_guard` in `core/caddy/Caddyfile` is
  what keeps Grafana off the public internet. It is fail-closed by default; a
  way around it is a finding.
- **Secret handling** — anything in this repo that would cause `.env` values to
  be logged, baked into an image, or exposed over the network.
- **Defaults that are unsafe if followed** — `.env.example` is meant to produce
  a secure instance when filled in as instructed.

Known and deliberate, so not findings on their own:

- `promtail` mounts the Docker socket read-only to collect container logs. That
  is a meaningful privilege, it is why the observability profile is opt-in, and
  it is documented in the README.
- Image tags default to `latest`. Pinning is offered in `.env.example`; tracking
  a moving tag is the operator's choice.

## Supported versions

Only the current `master`, matching the images it pulls.
