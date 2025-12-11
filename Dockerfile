# Caddy SSL Proxy with Cloudflare DNS plugin
#
# Uses DNS-01 Let's Encrypt via Cloudflare API for automatic SSL.
# This allows certificate provisioning for custom domains on Akash Network.

FROM caddy:2-builder AS builder

RUN xcaddy build \
    --with github.com/caddy-dns/cloudflare

FROM caddy:2

COPY --from=builder /usr/bin/caddy /usr/bin/caddy
COPY Caddyfile /etc/caddy/Caddyfile

EXPOSE 443 8080 2019

HEALTHCHECK --interval=30s --timeout=3s --start-period=30s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1
