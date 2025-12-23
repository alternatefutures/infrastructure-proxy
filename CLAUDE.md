# CLAUDE.md - Infrastructure Proxy

This file provides guidance to Claude Code when working with the SSL termination proxy.

## Project Overview

Pingap-based SSL termination proxy for all AlternateFutures services running on Akash Network. Uses Cloudflare Origin Certificates for end-to-end encryption and IP leases for dedicated public IP addresses.

**Last Updated**: 2025-12-23

## Current Deployment

<!-- DEPLOYMENTS_START -->
| Field | Value |
|-------|-------|
| **DSEQ** | 24750686 |
| **Provider** | Europlots (`akash18ga02jzaq8cw52anyhzkwta5wygufgu6zsz6xc`) |
| **Dedicated IP** | 62.3.50.133 |
| **Image** | `ghcr.io/alternatefutures/infrastructure-proxy-pingap:main` |
| **Status** | Active |
<!-- DEPLOYMENTS_END -->

**Source of Truth**: Deployment info managed in `admin/infrastructure/deployments.ts`

## Key Files

| File | Purpose |
|------|---------|
| `Dockerfile` | Pingap image build |
| `pingap.toml` | Static proxy configuration |
| `entrypoint.sh` | Container startup (converts pipe-separated certs to PEM) |
| `deploy-akash-ip-lease.yaml` | SDL template for IP lease deployments |
| `scripts/generate_sdl.py` | Generates deployment SDL with certificates |
| `.github/workflows/build-and-deploy.yml` | CI/CD pipeline |
| `docs/AKASH-IP-LEASE.md` | Detailed IP lease documentation |

## CRITICAL: Deployment Process

### ALWAYS Use GitHub Actions

**DO NOT manually format certificates.** The GitHub Actions workflow handles this correctly.

1. Push changes to `main` branch
2. Workflow builds image and pushes to GHCR
3. Workflow generates SDL with certificates from GitHub secrets
4. Download `deploy-sdl` artifact from workflow run
5. Deploy via Akash Console or MCP

### Certificate Format

The entrypoint expects **pipe-separated** PEM format, NOT escaped newlines:

```
# CORRECT (pipes as line separators)
-----BEGIN CERTIFICATE-----|MIIEsj...|...|-----END CERTIFICATE-----

# WRONG (escaped newlines)
-----BEGIN CERTIFICATE-----\nMIIEsj...\n...\n-----END CERTIFICATE-----

# WRONG (actual newlines in YAML)
-----BEGIN CERTIFICATE-----
MIIEsj...
-----END CERTIFICATE-----
```

The `entrypoint.sh` converts pipes to newlines:
```bash
echo "$PINGAP_TLS_CERT" | tr '|' '\n' > "$CERT_FILE"
```

### IP Lease Requirements

IP leases bypass provider nginx, enabling custom domain routing. **REQUIRED** for this proxy.

SDL must include:
```yaml
endpoints:
  proxy-ip:
    kind: ip

services:
  ssl-proxy:
    expose:
      - port: 443
        to:
          - global: true
            ip: proxy-ip  # Binds to leased IP
```

## Known Provider Issues

| Provider | Status | Notes |
|----------|--------|-------|
| **DigitalFrontier** (`akash1aaul837r7en7hpk9wv2svg8u78fdq0t2j2e82z`) | IP pool exhausted (2025-12-23) | Was previously working, now no IPs available |
| **Europlots** (`akash18ga02jzaq8cw52anyhzkwta5wygufgu6zsz6xc`) | Working | Confirmed IP lease allocation (62.3.50.133) |

When deploying, if IP lease not allocated:
1. Close deployment
2. Redeploy and select a different provider from the bids
3. Providers bid even if they don't have IPs available (known issue)

## Common Operations

### Check Deployment Status
```
mcp__akash__get-deployment with dseq=24750686
```

### View Logs
```
mcp__akash__get-logs with:
  owner: akash1degudmhf24auhfnqtn99mkja3xt7clt9um77tn
  dseq: 24750686
  gseq: 1
  oseq: 1
  provider: akash18ga02jzaq8cw52anyhzkwta5wygufgu6zsz6xc
```

### Check Services (verify IP allocation)
```
mcp__akash__get-services with same parameters
# Look for "ips" field - should show IP:443 and IP:80
```

### Add Funds
```
mcp__akash__add-funds with:
  address: akash1degudmhf24auhfnqtn99mkja3xt7clt9um77tn
  dseq: 24750686
  amount: 5000000uakt
```

## Domains Routed

All domains point to dedicated IP (62.3.50.133):

| Domain | Backend |
|--------|---------|
| `alternatefutures.ai` | Landing page |
| `auth.alternatefutures.ai` | Auth service |
| `api.alternatefutures.ai` | GraphQL API |
| `app.alternatefutures.ai` | Web dashboard |
| `docs.alternatefutures.ai` | Documentation |
| `secrets.alternatefutures.ai` | Infisical secrets |

### Secrets Service Fallback

If proxy is down, secrets can be accessed directly. See `service-secrets/CLAUDE.md` for emergency procedure:
- Direct ingress: `ddchr1pel5e0p8i0c46drjpclg.ingress.europlots.com`
- Requires DNS change to CNAME + Cloudflare Transform Rule

## Troubleshooting

### Container not starting (0/1 ready)
- Check logs for certificate errors
- Verify certificate format is pipe-separated
- Use `mcp__akash__get-logs` to see startup errors

### IP not allocated (ips: {})
- Provider may be out of IPs
- Close deployment and try different provider
- Verify SDL has `endpoints` section at top level

### 502 Bad Gateway
- Check backend services are running
- Verify upstream addresses in `pingap.toml`
- Check health endpoint: `curl http://<provider>:<port>/health`

### NAT Hairpin Issue (upstreams timing out)
If proxy logs show `upstreams_healthy_status="service:0/1"` for services on the same provider:

**Cause**: The proxy cannot reach its own provider's public ingress from within that provider's network. This is a NAT hairpin limitation.

**Symptoms**:
```
upstreams_healthy_status="ipfs:0/1, auth:0/1, api:1/1, secrets:0/1"
# Services on SAME provider (Europlots) = 0/1 timeout
# Services on DIFFERENT provider (subangle) = 1/1 healthy
```

**Solutions**:
1. **For IPFS**: Use public gateway (e.g., `gateway.pinata.cloud`) instead of provider's internal gateway
2. **For other services**: Either:
   - Move backend services to different providers
   - Move proxy to a provider different from backends
   - Use Kubernetes internal service discovery (if available)

### Certificate errors
- Ensure Cloudflare Origin Certificate covers all domains
- Check certificate not expired
- Verify pipe-separated format in SDL

## After Deployment

1. Update `admin/infrastructure/deployments.ts` with new DSEQ, provider, IP
2. Update Cloudflare DNS A records to point to new IP
3. Verify health: `curl -k https://<dedicated-ip>/health`
4. Test each domain: `curl -I https://auth.alternatefutures.ai`

## Related

- [`infrastructure-dns`](../infrastructure-dns) - Multi-provider DNS management
- [`service-secrets`](../service-secrets) - Infisical secrets (isolated from proxy)
- [`admin/infrastructure/deployments.ts`](../admin/infrastructure/deployments.ts) - Deployment registry
