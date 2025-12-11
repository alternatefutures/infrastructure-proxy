# AlternateFutures SSL Proxy (Pingap)

High-performance SSL termination proxy for AlternateFutures services running on Akash Network. Built on Cloudflare's Pingora framework.

## Current Deployment

| Field | Value |
|-------|-------|
| **DSEQ** | 24576255 |
| **Provider** | Europlots (`akash162gym3szcy9d993gs3tyu0mg2ewcjacen9nwsu`) |
| **Image** | `ghcr.io/alternatefutures/infrastructure-proxy-pingap:main` |
| **Status** | Running, awaiting Cloudflare zone activation |

## Overview

This proxy solves a key challenge with Akash Network: providers use DNS-01 Let's Encrypt challenges with wildcard certificates for their own domains, but **cannot** provision certificates for tenant custom domains.

Our solution uses Pingap (built on Pingora) with native Cloudflare DNS support to obtain Let's Encrypt certificates via DNS-01 challenges, enabling automatic SSL for custom domains on Akash.

### Why Pingap over Caddy?

| Feature | Pingap | Caddy |
|---------|--------|-------|
| Memory usage | ~15MB | ~30MB |
| CPU usage | 70% less | Baseline |
| DNS-01 Cloudflare | Native | Plugin required |
| Custom build | No | Yes (xcaddy) |
| Framework | Rust (Pingora) | Go |

## Architecture

```
                         Internet
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│              DNS (Cloudflare + Google + deSEC)              │
│                   Multi-provider redundancy                  │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    Akash Provider Ingress                    │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                     SSL Proxy (Pingap)                       │
│                                                              │
│  • DNS-01 Let's Encrypt via Cloudflare API                  │
│  • Automatic cert provisioning & renewal                     │
│  • Built on Cloudflare's Pingora (Rust)                     │
│  • Routes to backend services                                │
└───────────────────────────┬─────────────────────────────────┘
                            │
            ┌───────────────┼───────────────┐
            ▼               ▼               ▼
      ┌──────────┐   ┌──────────┐   ┌──────────┐
      │ Auth API │   │ GraphQL  │   │ Web App  │
      │  :3000   │   │   API    │   │  :3000   │
      └──────────┘   │  :4000   │   └──────────┘
                     └──────────┘
```

## Files

| File | Purpose |
|------|---------|
| `Dockerfile` | Pingap image with config |
| `pingap.toml` | Proxy configuration with DNS-01 TLS |
| `deploy-akash.yaml` | Akash SDL for deployment |
| `SSL_ARCHITECTURE.md` | Detailed SSL/TLS documentation |
| `Caddyfile` | (Deprecated) Old Caddy config |

## Domains Handled

| Domain | Backend |
|--------|---------|
| `auth.alternatefutures.ai` | Auth service |
| `api.alternatefutures.ai` | GraphQL API |
| `app.alternatefutures.ai` | Web dashboard |

## Prerequisites

1. **Cloudflare Account** (free tier)
   - Add `alternatefutures.ai` domain
   - Create API token with `Zone:DNS:Edit` permission
   - Zone must be `active` status

2. **Multi-Provider DNS** (see `infrastructure-dns` repo)
   - Cloudflare, Google Cloud DNS, deSEC
   - ACME challenges delegated to Cloudflare

## Local Development

```bash
# Build the image
docker build -t ssl-proxy .

# Run locally
docker run -p 443:443 -p 8080:8080 \
  -e PINGAP_DNS_SERVICE_URL="https://api.cloudflare.com?token=your-token" \
  ssl-proxy

# Health check
curl http://localhost:8080/health
```

## Deployment

### Via GitHub Actions

1. Push to `main` branch triggers build
2. Image pushed to `ghcr.io/alternatefutures/infrastructure-proxy-pingap`
3. Manual deployment via Akash Console or MCP

### Manual Akash Deployment

```bash
# Using Akash MCP or Console with deploy-akash.yaml
# Set env var:
PINGAP_DNS_SERVICE_URL=https://api.cloudflare.com?token=<CF_API_TOKEN>
```

## Environment Variables

| Variable | Format | Description |
|----------|--------|-------------|
| `PINGAP_DNS_SERVICE_URL` | `https://api.cloudflare.com?token=xxx` | Cloudflare API for DNS-01 |

## Monitoring

### Health Check

```bash
curl http://<provider>:<health-port>/health
# Current: http://provider.sa1.pl:32077/health
```

### Certificate Status

```bash
echo | openssl s_client -connect auth.alternatefutures.ai:443 2>/dev/null | \
  openssl x509 -noout -dates -issuer
```

### Logs

Via Akash MCP:
```
get-logs with dseq=24576255, provider=akash162gym3szcy9d993gs3tyu0mg2ewcjacen9nwsu
```

## Troubleshooting

### Certificate not provisioning

1. Check Cloudflare zone status is `active` (not `initializing`)
2. Verify `PINGAP_DNS_SERVICE_URL` format is correct
3. Check logs for ACME errors: `lookup dns txt record of _acme-challenge...`

### 502 Bad Gateway

1. Verify backend services are running
2. Check backend addresses in `pingap.toml`
3. Ensure Akash internal networking allows service-to-service communication

### Image caching on provider

If provider serves old image:
- Change image name (append `-v2`, etc.)
- Or use SHA tag instead of `:main`

## Related Repositories

- [`infrastructure-dns`](../infrastructure-dns) - Multi-provider DNS management
- [`service-auth`](../service-auth) - Authentication service
- [`service-cloud-api`](../service-cloud-api) - GraphQL API
