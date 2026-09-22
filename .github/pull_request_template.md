## What changes for someone running this stack

<!-- The people affected by this repo are running it in production, ours
     included. Say what they have to do differently: a new variable, a
     re-assembled edge config, a manual step on upgrade, or nothing. -->

## Checks

- [ ] `docker compose config` resolves with no warnings, for `core,product` and with `observability`
- [ ] Any new setting is in **both** `docker-compose.yaml` and `.env.example`
- [ ] No hardcoded domains, IPs or host paths — defaults suit a self-hoster, not our deployment
- [ ] `./scripts/check-config.sh` passes
- [ ] I have signed the [CLA](https://github.com/homeaccounting/site/blob/master/CLA.md) (a bot will ask on your first PR)
