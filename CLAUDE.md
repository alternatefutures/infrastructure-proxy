# Infrastructure Proxy — contributor notes

This file exists to keep automation/models aligned when working on the SSL termination proxy (`Pingap`).

## Source of truth (avoid drift)

- **Current production deployment state** (DSEQ, provider, dedicated IP): repo root `DEPLOYMENTS.md`
- **Proxy-only deployment registry** (machine-readable): `infrastructure-proxy/deployments.json`

Do **not** hardcode DSEQs/providers/IPs into docs/scripts unless they are generated from the registries above.

## What this component does

- Terminates TLS using a **Cloudflare Origin Certificate**
- Routes custom domains (e.g. `auth.alternatefutures.ai`, `api.alternatefutures.ai`) to the correct Akash provider ingresses

## Key files

- `pingap.toml`: static routing configuration (baked into the image)
- `entrypoint.sh`: converts pipe-separated PEM env vars into files and starts Pingap
- `deploy-akash-ip-lease.yaml`: IP-lease SDL (dedicated IP); used by `akash-mcp/scripts/redeploy-all.ts`
- `scripts/update-deployment-registry.js`: updates `deployments.json` after deploys

## Certificate format (critical)

`PINGAP_TLS_CERT` / `PINGAP_TLS_KEY` must be **pipe-separated** PEM:

```
-----BEGIN CERTIFICATE-----|...|-----END CERTIFICATE-----
```

The entrypoint converts pipes to newlines before starting Pingap.

## Operational notes

- **NAT hairpin**: do not deploy backends that must be reached *through the proxy* on the same provider as the proxy. (The proxy can’t reliably reach its own provider’s public ingress from inside that provider’s network.)
- **Immutable image tags**: avoid `:latest`/`:main` when iterating; use SHA tags so providers actually pull the updated image.

