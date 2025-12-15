#!/bin/sh
# Entrypoint script - writes TLS certs from env vars to files
# Required for Cloudflare Origin Certificate with Pingap
set -e

CERT_DIR="/etc/pingap/certs"
mkdir -p "$CERT_DIR"

# Write certificate if provided
if [ -n "$PINGAP_TLS_CERT" ]; then
    printf '%s\n' "$PINGAP_TLS_CERT" > "$CERT_DIR/origin.crt"
    echo "Certificate written to $CERT_DIR/origin.crt"
fi

# Write private key if provided
if [ -n "$PINGAP_TLS_KEY" ]; then
    printf '%s\n' "$PINGAP_TLS_KEY" > "$CERT_DIR/origin.key"
    chmod 600 "$CERT_DIR/origin.key"
    echo "Private key written to $CERT_DIR/origin.key"
fi

# Start Pingap
exec pingap -c /etc/pingap/pingap.toml "$@"
