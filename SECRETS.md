# Environment Variables & Secrets

This document lists all environment variables required for `infrastructure-proxy`.

## Infisical Path

```
/production/infrastructure-proxy/
```

## Required Variables

### TLS Certificates (Cloudflare Origin)

| Variable | Description | Format |
|----------|-------------|--------|
| `PINGAP_TLS_CERT` | Cloudflare Origin Certificate (PEM) | Newlines as `\n` |
| `PINGAP_TLS_KEY` | Cloudflare Origin Private Key (PEM) | Newlines as `\n` |

## Certificate Format

Certificates must be stored with newlines escaped as `\n`:

```bash
# Convert certificate for storage
cat origin.crt | awk '{printf "%s\\n", $0}'

# Convert private key for storage
cat origin.key | awk '{printf "%s\\n", $0}'
```

The entrypoint script converts these back to proper PEM format at runtime.

## Backend Configuration

Backend URLs are configured in `pingap.toml`, not environment variables:

| Backend | Upstream URL | Notes |
|---------|-------------|-------|
| auth | `ubsm31q4ol97b1pi5l06iognug.ingress.europlots.com:443` | Auth service |
| api | `rvknp4kjg598n8uslgnovkrdpk.ingress.gpu.subangle.com:443` | API service |
| secrets | `v8c1fui9p1dah5m86ctithi5ok.ingress.europlots.com:443` | Infisical |
| ipfs | `ubsm31q4ol97b1pi5l06iognug.ingress.europlots.com:32160` | IPFS gateway |

## GitHub Actions Secrets

For automated deployments, set these secrets in the repository:

| Secret | Description |
|--------|-------------|
| `CLOUDFLARE_ORIGIN_CERT` | Full certificate PEM (with `\n` escapes) |
| `CLOUDFLARE_ORIGIN_KEY` | Full private key PEM (with `\n` escapes) |

## Akash Deployment

### Current Deployment
- **DSEQ:** 24650196
- **Provider:** DigitalFrontier
- **Dedicated IP:** 77.76.13.214

### SDL Environment Variables

In `deploy-akash-ip-lease.yaml`:

```yaml
env:
  - PINGAP_TLS_CERT=-----BEGIN CERTIFICATE-----\n...\n-----END CERTIFICATE-----\n
  - PINGAP_TLS_KEY=-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n
```

## Generating New Certificates

1. Go to Cloudflare Dashboard → SSL/TLS → Origin Server
2. Create Certificate:
   - Let Cloudflare generate private key
   - Hostnames: `*.alternatefutures.ai, alternatefutures.ai`
   - Validity: 15 years
3. **IMPORTANT:** Save both cert and key immediately (key shown only once)
4. Convert for env vars:
   ```bash
   cat origin.crt | awk '{printf "%s\\n", $0}'
   cat origin.key | awk '{printf "%s\\n", $0}'
   ```

## Priority Order for Setup

1. **Critical** (TLS won't work without):
   - `PINGAP_TLS_CERT`
   - `PINGAP_TLS_KEY`

## Security Notes

- Private keys are NEVER committed to the repository
- `certs/` directory is in `.gitignore`
- Certificates are injected at runtime via environment variables
- Only Cloudflare's proxy can verify Origin Certificates (not publicly trusted)
- Keep DNS records "Proxied" (orange cloud) in Cloudflare
