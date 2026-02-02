# Deployment Status Tracker

**Last Updated:** 2026-02-02 19:57 UTC

## Active Deployments

### SSL Proxy (infrastructure-proxy)
- **DSEQ:** `25312670`
- **Provider:** DigitalFrontier (`akash1aaul837r7en7hpk9wv2svg8u78fdq0t2j2e82z`)
- **Dedicated IP:** `77.76.13.213`
- **DNS:** secrets.alternatefutures.ai → 77.76.13.213
- **Status:** ✅ ACTIVE (but needs config update for new Infisical backend)
- **Action Needed:** Update secrets backend to `uvhirubqe1aa1att76elejdi3c.ingress.europlots.com:80`

### Infisical Secrets
- **DSEQ:** `25354545`
- **Provider:** Europlots (`akash18ga02jzaq8cw52anyhzkwta5wygufgu6zsz6xc`)
- **Ingress:** `uvhirubqe1aa1att76elejdi3c.ingress.europlots.com`
- **Direct URL:** http://uvhirubqe1aa1att76elejdi3c.ingress.europlots.com
- **Public URL:** https://secrets.alternatefutures.ai (via proxy - not working yet)
- **Status:** ✅ ACTIVE
- **SMTP:** ✅ WORKING (sending from noreply@secrets.alternatefutures.ai)
- **Backup:** ❌ No automated backup (backup container available in `infisical-akash-with-backup.yaml`)

---

## Closed Deployments (DO NOT USE)

### Proxy Deployments
| DSEQ | Provider | IP | Closed Date | Notes |
|------|----------|----|----|-------|
| 24758214 | leet.haus | 170.75.255.101 | ~2026-01 | Out of funds |
| 24750686 | Europlots | 62.3.50.133 | ~2026-01 | Out of funds |

### Infisical Deployments
| DSEQ | Provider | Ingress | Closed Date | Reason |
|------|----------|---------|-------------|---------|
| 25312419 | Europlots | qc61p3qvrl8rl3qra6i3bsl5u4 | 2026-02-02 | Redeployed with SMTP fix |
| 24645907 | Europlots | v8c1fui9p1dah5m86ctithi5ok | Earlier | Old deployment |

---

## Current Issues

1. **Proxy not routing to new Infisical**
   - Proxy at 77.76.13.213 needs config update
   - Need DSEQ to update configuration
   - Currently pointing to old Infisical ingress

2. **No automated backups**
   - Current Infisical deployment doesn't have backup container
   - SDL with backup ready: `infisical-akash-with-backup.yaml`
   - Should redeploy with backup once SMTP tested

---

## Next Steps

1. Get proxy DSEQ from user
2. Update proxy config to point to new Infisical
3. Test full flow (invite links working via https://secrets.alternatefutures.ai)
4. Once confirmed working, redeploy Infisical with backup container
5. Update this document with correct proxy DSEQ

---

## Quick Reference

**Current Infisical Access:**
- Direct: http://uvhirubqe1aa1att76elejdi3c.ingress.europlots.com
- Via Proxy (not working): https://secrets.alternatefutures.ai

**Backup Location:**
- ~/Projects/alternatefutures/service-secrets/backups/backup_current_20260202_110847
- 31 secrets backed up across 6 folders
