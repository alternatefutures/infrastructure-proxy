# Hairpin NAT Issue in Akash Deployments

## Summary

When deploying a reverse proxy on Akash Network, you must deploy it on a **different provider** than your backend services to avoid hairpin NAT issues.

## What is Hairpin NAT?

Hairpin NAT (also called NAT loopback or NAT reflection) occurs when traffic from an internal network device tries to reach another device on the same network using its external/public IP address.

```
┌─────────────────────────────────────────────────────────────┐
│                    HAIRPIN NAT FLOW                          │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   Container A ──────► Public IP ──────► Container B          │
│      (proxy)    OUT      86.33.22.194     IN    (backend)   │
│                         │                │                   │
│                         └───── HAIRPIN ──┘                   │
│                       Traffic must turn around               │
│                                                              │
│   Many network configurations block this!                    │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## The Problem on Akash

When we deployed the Pingap proxy on the Europlots provider:

| Backend Service | Provider | Ingress URL | IP Address |
|-----------------|----------|-------------|------------|
| **Proxy** | Europlots | `*.ingress.europlots.com` | 86.33.22.194 |
| Auth | Europlots | `ubsm...ingress.europlots.com` | 86.33.22.194 |
| Secrets | Europlots | `v8c1f...ingress.europlots.com` | 86.33.22.194 |
| IPFS | Europlots | `provider.europlots.com:32160` | 86.33.22.194 |
| API | Subangle | `rvknp...ingress.gpu.subangle.com` | 116.203.3.247 |

### Health Check Results (Proxy on Europlots)

```
# API on different provider - PASSED (29ms)
health check is done name="api" elapsed="29ms"

# Auth on same provider - TIMEOUT (3000ms)
health check is done name="auth" elapsed="3014ms"
upstream auth(86.33.22.194:443) becomes unhealthy

# Secrets on same provider - TIMEOUT (3000ms)
health check is done name="secrets" elapsed="3014ms"
upstream secrets(86.33.22.194:443) becomes unhealthy

# IPFS on same provider - TIMEOUT (3000ms)
health check is done name="ipfs" elapsed="3013ms"
upstream ipfs(86.33.22.194:32160) becomes unhealthy
```

## The Solution

Deploy the proxy on a **different provider** than your backend services:

| Backend Service | Provider | Ingress URL | IP Address |
|-----------------|----------|-------------|------------|
| **Proxy** | D3Akash | `*.ingress.d3akash.cloud` | Different IP |
| Auth | Europlots | `ubsm...ingress.europlots.com` | 86.33.22.194 |
| Secrets | Europlots | `v8c1f...ingress.europlots.com` | 86.33.22.194 |
| IPFS | Europlots | `provider.europlots.com:32160` | 86.33.22.194 |
| API | Subangle | `rvknp...ingress.gpu.subangle.com` | 116.203.3.247 |

### Health Check Results (Proxy on D3Akash - Different Provider)

```
# ALL backends healthy - traffic flows normally over internet
upstreams_healthy_status="auth:1/1, secrets:1/1, api:1/1, ipfs:1/1"

health check is done name="api" elapsed="15ms"
health check is done name="auth" elapsed="26ms"
health check is done name="secrets" elapsed="27ms"
health check is done name="ipfs" elapsed="30ms"
```

## Why Other Providers Don't Have This Issue

When the proxy is on a different provider:

```
┌─────────────────────────────────────────────────────────────┐
│                    NORMAL TRAFFIC FLOW                       │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   D3Akash Provider              Europlots Provider           │
│   ┌──────────────┐              ┌──────────────┐            │
│   │   Proxy      │ ──Internet──►│   Backend    │            │
│   │              │              │   Services   │            │
│   └──────────────┘              └──────────────┘            │
│   IP: Different                 IP: 86.33.22.194            │
│                                                              │
│   Traffic goes OUT to internet, reaches DIFFERENT IP        │
│   No hairpin needed - normal external routing               │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

1. **External Traffic Path**: Proxy connects to backend's public IP over the internet
2. **No Hairpin Required**: Traffic doesn't need to loop back to the same network
3. **Standard Routing**: Works with any network configuration

## Deployment Guidelines

### Do:
- Deploy your reverse proxy on a **different Akash provider** than your backend services
- Choose providers with good network connectivity to your backend providers
- Use the `signedBy` SDL attribute to **exclude** providers where your backends run

### Don't:
- Deploy proxy and backends on the same provider if proxy needs to reach backends via public URLs
- Assume all providers support hairpin NAT (most don't)
- Use internal service names across different Akash deployments (they're isolated)

## SDL Example: Excluding Specific Providers

```yaml
# To exclude Europlots (where our backends run):
profiles:
  placement:
    akash:
      attributes:
        host: akash
      # DO NOT use signedBy if your backends are on this provider
      # signedBy:
      #   anyOf:
      #     - "akash18ga02jzaq8cw52anyhzkwta5wygufgu6zsz6xc"  # Europlots
```

By leaving `signedBy` open, you'll receive bids from multiple providers and can choose one that's different from where your backends run.

## Current Deployment

- **Proxy**: D3Akash (`akash1u5cdg7k3gl43mukca4aeultuz8x2j68mgwn28e`)
  - Ingress: `5gnp42knvhd43056p0ft3ba3jc.ingress.d3akash.cloud`
  - DSEQ: 24647767
- **Auth, Secrets, IPFS**: Europlots (`akash18ga02jzaq8cw52anyhzkwta5wygufgu6zsz6xc`)
- **API**: Subangle (different provider)

## Debugging Tips

If health checks are failing with timeouts:

1. Check which provider your proxy is deployed on
2. Check which providers your backends are deployed on
3. If same provider, redeploy proxy to a different provider
4. Use `get-services` to find ingress URLs and verify provider info
