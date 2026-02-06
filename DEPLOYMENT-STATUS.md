# Deployment Status Tracker

**Last Updated:** 2026-02-06

## Active Deployments

### SSL Proxy (infrastructure-proxy)
- **DSEQ:** `25312670`
- **Provider:** DigitalFrontier (`akash1aaul837r7en7hpk9wv2svg8u78fdq0t2j2e82z`)
- **Dedicated IP:** `77.76.13.213`
- **Image:** `ghcr.io/alternatefutures/infrastructure-proxy-pingap:main`
- **Status:** Running
- **Domains Routed:** auth, api, app, docs.alternatefutures.ai

### Infisical Secrets
- **DSEQ:** `25354545`
- **Provider:** Europlots (`akash18ga02jzaq8cw52anyhzkwta5wygufgu6zsz6xc`)
- **Ingress:** `uvhirubqe1aa1att76elejdi3c.ingress.europlots.com`
- **Direct URL:** http://uvhirubqe1aa1att76elejdi3c.ingress.europlots.com
- **Public URL:** https://secrets.alternatefutures.ai (direct to Akash, not through proxy)
- **Status:** Running
- **SMTP:** Working (sending from noreply@secrets.alternatefutures.ai)

### Backend Services (routed through proxy)

| Service | DSEQ | Provider | Status |
|---------|------|----------|--------|
| service-cloud-api | 25411473 | leet.haus | Running |
| service-auth | 25412621 | tagus.host | Running |

---

## Closed Deployments (Historical)

### Proxy Deployments
| DSEQ | Provider | IP | Closed Date | Notes |
|------|----------|----|----|-------|
| 24758214 | leet.haus | 170.75.255.101 | ~2026-01 | Out of funds |
| 24750686 | Europlots | 62.3.50.133 | ~2026-01 | Out of funds |

### Auth Service Deployments
| DSEQ | Provider | Closed Date | Notes |
|------|----------|-------------|-------|
| 25412121 | tagus.host | 2026-02-06 | Replaced by 25412621 (version hash mismatch) |
| 25411471 | tagus.host | 2026-02-06 | Original auth deployment |

### Infisical Deployments
| DSEQ | Provider | Ingress | Closed Date | Reason |
|------|----------|---------|-------------|---------|
| 25312419 | Europlots | qc61p3qvrl8rl3qra6i3bsl5u4 | 2026-02-02 | Redeployed with SMTP fix |
| 24645907 | Europlots | v8c1fui9p1dah5m86ctithi5ok | Earlier | Old deployment |

---

## Quick Reference

**SSL Proxy:** 77.76.13.213 (DSEQ 25312670)
**Infisical Direct:** http://uvhirubqe1aa1att76elejdi3c.ingress.europlots.com
**Infisical Public:** https://secrets.alternatefutures.ai
