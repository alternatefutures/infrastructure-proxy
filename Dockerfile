# Pingap SSL Proxy - Built on Cloudflare's Pingora
#
# High-performance reverse proxy with Cloudflare Origin Certificate.
# Uses static TLS cert instead of ACME DNS-01 (avoids DNS propagation issues).
# Uses ~70% less resources than nginx/caddy.

FROM vicanso/pingap:latest

# Copy configuration
COPY pingap.toml /etc/pingap/pingap.toml
COPY entrypoint.sh /entrypoint.sh

# Make entrypoint executable and create directories
RUN chmod +x /entrypoint.sh && \
    mkdir -p /etc/pingap/certs /data/pingap /var/log/pingap

# Expose ports
EXPOSE 443 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=30s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

# Use entrypoint to inject certs before starting Pingap
ENTRYPOINT ["/entrypoint.sh"]
