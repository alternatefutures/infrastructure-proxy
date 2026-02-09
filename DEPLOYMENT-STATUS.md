# Deployment status (deprecated)

This file previously duplicated “what’s live” deployment state and drifted over time.

## Source of truth (current production state)

- `DEPLOYMENTS.md` (repo root)
- `.github/DEPLOYMENTS.md` (repo root)

Those files are what other tooling/scripts should reference for **current** DSEQs, providers, and endpoints.

## Proxy-specific registry

For the SSL proxy only, use:

- `infrastructure-proxy/deployments.json`

This JSON registry is updated by CI/scripts (see `infrastructure-proxy/scripts/update-deployment-registry.js`).
