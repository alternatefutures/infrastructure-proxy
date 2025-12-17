#!/bin/sh
# Entrypoint script - injects TLS certs into pingap.toml from env vars
# Required for Cloudflare Origin Certificate with Pingap
set -e

CONFIG_TEMPLATE="/etc/pingap/pingap.toml"
CONFIG_RUNTIME="/tmp/pingap-runtime.toml"

echo "=== TLS Certificate Setup ==="

# Convert escaped newlines to actual newlines and format as TOML multiline string
format_pem_for_toml() {
    # Input: PEM with \n escape sequences
    # Output: TOML multiline string with actual newlines
    printf '%b' "$1" | sed 's/$/\\n/' | tr -d '\n' | sed 's/\\n$//'
}

# Check for required env vars
if [ -z "$PINGAP_TLS_CERT" ]; then
    echo "ERROR: PINGAP_TLS_CERT is not set!"
    exit 1
fi

if [ -z "$PINGAP_TLS_KEY" ]; then
    echo "ERROR: PINGAP_TLS_KEY is not set!"
    exit 1
fi

# Convert pipe-separated cert to actual PEM format with newlines
# Input format: "-----BEGIN CERTIFICATE-----|MIIDOz...|...|-----END CERTIFICATE-----"
CERT_PEM=$(echo "$PINGAP_TLS_CERT" | tr '|' '\n')
KEY_PEM=$(echo "$PINGAP_TLS_KEY" | tr '|' '\n')

echo "Certificate first line: $(echo "$CERT_PEM" | head -1)"
echo "Certificate last line: $(echo "$CERT_PEM" | tail -1)"
echo "Key first line: $(echo "$KEY_PEM" | head -1)"
echo "Key last line: $(echo "$KEY_PEM" | tail -1)"

# Verify PEM format
if ! echo "$CERT_PEM" | grep -q "BEGIN CERTIFICATE"; then
    echo "ERROR: Certificate does not appear to be valid PEM format!"
    exit 1
fi
if ! echo "$KEY_PEM" | grep -q "BEGIN PRIVATE KEY"; then
    echo "ERROR: Private key does not appear to be valid PEM format!"
    exit 1
fi

echo "Certificate and key PEM format validated"

# Create the runtime config with inline certificates
# We need to use heredoc and cat to properly handle multiline PEM content
cat > "$CONFIG_RUNTIME" << 'CONFIGEOF'
# Pingap Configuration - SSL Proxy for AlternateFutures
# Built on Cloudflare's Pingora framework
# Runtime generated config with inline certificates

[basic]
name = "alternatefutures-proxy"
threads = 2
work_stealing = true
grace_period = "10s"
pid_file = "/tmp/pingap.pid"

CONFIGEOF

# Add certificate section with inline PEM content
cat >> "$CONFIG_RUNTIME" << CERTEOF
# Cloudflare Origin Certificate (inline)
[certificates.alternatefutures]
tls_cert = """
$CERT_PEM
"""
tls_key = """
$KEY_PEM
"""
is_default = true

CERTEOF

# Append the rest of the config (upstreams, locations, servers)
cat >> "$CONFIG_RUNTIME" << 'RESTEOF'
# Auth Service Backend
[upstreams.auth]
addrs = ["ubsm31q4ol97b1pi5l06iognug.ingress.europlots.com:443"]
sni = "ubsm31q4ol97b1pi5l06iognug.ingress.europlots.com"
connection_timeout = "10s"
health_check_connection_timeout = "10s"
verify_cert = false

# API Service Backend
[upstreams.api]
addrs = ["rvknp4kjg598n8uslgnovkrdpk.ingress.gpu.subangle.com:443"]
sni = "rvknp4kjg598n8uslgnovkrdpk.ingress.gpu.subangle.com"
connection_timeout = "10s"
health_check_connection_timeout = "10s"
verify_cert = false

# IPFS Gateway Backend (for static sites)
[upstreams.ipfs]
addrs = ["provider.europlots.com:32160"]
connection_timeout = "30s"
health_check_connection_timeout = "10s"

# Secrets (Infisical) Backend
[upstreams.secrets]
addrs = ["ddchr1pel5e0p8i0c46drjpclg.ingress.europlots.com:80"]
connection_timeout = "10s"
health_check_connection_timeout = "10s"

# Route: Auth Service
[locations.auth]
upstream = "auth"
host = "auth.alternatefutures.ai"
path = "/"
proxy_set_headers = ["Host: ubsm31q4ol97b1pi5l06iognug.ingress.europlots.com", "X-Forwarded-Proto: https", "X-Forwarded-Host: auth.alternatefutures.ai", "X-Real-IP: $remote_addr"]

# Route: API Service
[locations.api]
upstream = "api"
host = "api.alternatefutures.ai"
path = "/"
proxy_set_headers = ["Host: rvknp4kjg598n8uslgnovkrdpk.ingress.gpu.subangle.com", "X-Forwarded-Proto: https", "X-Forwarded-Host: api.alternatefutures.ai", "X-Real-IP: $remote_addr"]

# Route: Main Website (IPFS-hosted web-app)
[locations.website]
upstream = "ipfs"
host = "alternatefutures.ai"
path = "/"
rewrite = "^(.*)$ /ipfs/QmU4VRKexpuA6RvYfXY9nUsgiHRMLDhxvZFi7ssGHn3aHj$1"
proxy_set_headers = ["X-Forwarded-Proto: https", "X-Real-IP: $remote_addr"]

# Route: Documentation (IPFS-hosted docs)
[locations.docs]
upstream = "ipfs"
host = "docs.alternatefutures.ai"
path = "/"
rewrite = "^(.*)$ /ipfs/QmeQe1QuyiAiyCrJLASixPtH2VW6xQZxcpqCHJsUTtxfUR$1"
proxy_set_headers = ["X-Forwarded-Proto: https", "X-Real-IP: $remote_addr"]

# Route: App Dashboard (IPFS-hosted web-app)
[locations.app]
upstream = "ipfs"
host = "app.alternatefutures.ai"
path = "/"
rewrite = "^(.*)$ /ipfs/QmU4VRKexpuA6RvYfXY9nUsgiHRMLDhxvZFi7ssGHn3aHj$1"
proxy_set_headers = ["X-Forwarded-Proto: https", "X-Real-IP: $remote_addr"]

# Route: Secrets (Infisical)
[locations.secrets]
upstream = "secrets"
host = "secrets.alternatefutures.ai"
path = "/"
proxy_set_headers = ["Host: ddchr1pel5e0p8i0c46drjpclg.ingress.europlots.com", "X-Forwarded-Proto: https", "X-Forwarded-Host: secrets.alternatefutures.ai", "X-Real-IP: $remote_addr"]

# Health check route
[locations.health]
path = "/health"
plugins = ["pingap:responseHeaders?X-Health-Check:ok", "pingap:mock?status=200&text=OK"]

# HTTP Server (for Akash ingress - Cloudflare handles TLS at edge)
[servers.http]
addr = "0.0.0.0:80"
locations = ["auth", "api", "website", "docs", "app", "secrets", "health"]

# HTTPS Server - uses global certificates from [certificates.alternatefutures]
[servers.https]
addr = "0.0.0.0:443"
locations = ["auth", "api", "website", "docs", "app", "secrets"]
global_certificates = true
tls_cipher_list = "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384"
tls_min_version = "1.2"
enabled_h2 = true

# Health check HTTP Server (for Akash health probes)
[servers.health]
addr = "0.0.0.0:8080"
locations = ["health"]
RESTEOF

echo "=== Generated Runtime Config ==="
echo "Config written to: $CONFIG_RUNTIME"
echo "Certificate section preview:"
grep -A 3 "certificates.alternatefutures" "$CONFIG_RUNTIME" | head -5

echo "=== Starting Pingap ==="
# Start Pingap with the runtime-generated config
exec pingap -c "$CONFIG_RUNTIME" "$@"
