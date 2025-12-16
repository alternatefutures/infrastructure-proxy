#!/bin/sh
# Entrypoint script - writes TLS certs from env vars to files
# Required for Cloudflare Origin Certificate with Pingap
set -e

CERT_DIR="/etc/pingap/certs"
mkdir -p "$CERT_DIR"

echo "=== TLS Certificate Setup ==="

# Write certificate if provided (use printf %b to interpret \n escape sequences)
if [ -n "$PINGAP_TLS_CERT" ]; then
    printf '%b\n' "$PINGAP_TLS_CERT" > "$CERT_DIR/origin.crt"
    echo "Certificate written to $CERT_DIR/origin.crt"
    echo "Certificate file size: $(wc -c < "$CERT_DIR/origin.crt") bytes"
    echo "Certificate lines: $(wc -l < "$CERT_DIR/origin.crt")"
    head -1 "$CERT_DIR/origin.crt"
    tail -1 "$CERT_DIR/origin.crt"
    # Verify it's a valid PEM
    if grep -q "BEGIN CERTIFICATE" "$CERT_DIR/origin.crt" && grep -q "END CERTIFICATE" "$CERT_DIR/origin.crt"; then
        echo "✓ Certificate PEM format validated"
    else
        echo "✗ ERROR: Certificate does not appear to be valid PEM format!"
    fi
else
    echo "✗ WARNING: PINGAP_TLS_CERT is not set!"
fi

# Write private key if provided
if [ -n "$PINGAP_TLS_KEY" ]; then
    printf '%b\n' "$PINGAP_TLS_KEY" > "$CERT_DIR/origin.key"
    chmod 600 "$CERT_DIR/origin.key"
    echo "Private key written to $CERT_DIR/origin.key"
    echo "Key file size: $(wc -c < "$CERT_DIR/origin.key") bytes"
    echo "Key lines: $(wc -l < "$CERT_DIR/origin.key")"
    head -1 "$CERT_DIR/origin.key"
    tail -1 "$CERT_DIR/origin.key"
    # Verify it's a valid PEM
    if grep -q "BEGIN PRIVATE KEY" "$CERT_DIR/origin.key" && grep -q "END PRIVATE KEY" "$CERT_DIR/origin.key"; then
        echo "✓ Private key PEM format validated"
    else
        echo "✗ ERROR: Private key does not appear to be valid PEM format!"
    fi
else
    echo "✗ WARNING: PINGAP_TLS_KEY is not set!"
fi

echo "=== Starting Pingap ==="
ls -la "$CERT_DIR/"

# Start Pingap with debug logging
exec pingap -c /etc/pingap/pingap.toml "$@"
