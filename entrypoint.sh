#!/bin/sh
# Entrypoint script - writes TLS certs to files and starts Pingap
# Required for Cloudflare Origin Certificate with Pingap
#
# This script:
# 1. Converts pipe-separated PEM to proper format
# 2. Writes cert/key to files
# 3. Starts Pingap with our config

echo "========================================"
echo "AlternateFutures SSL Proxy Entrypoint"
echo "========================================"
echo ""

CERT_FILE="/etc/pingap/certs/origin.crt"
KEY_FILE="/etc/pingap/certs/origin.key"
CONFIG_FILE="/etc/pingap/pingap.toml"

# Check for required env vars
if [ -z "$PINGAP_TLS_CERT" ]; then
    echo "ERROR: PINGAP_TLS_CERT environment variable is not set!"
    echo "This should contain the Cloudflare Origin Certificate in pipe-separated PEM format."
    exit 1
fi

if [ -z "$PINGAP_TLS_KEY" ]; then
    echo "ERROR: PINGAP_TLS_KEY environment variable is not set!"
    echo "This should contain the private key in pipe-separated PEM format."
    exit 1
fi

echo "Environment variables found. Converting certificates..."

# Convert pipe-separated cert to actual PEM format with newlines
# Input format: "-----BEGIN CERTIFICATE-----|MIIDOz...|...|-----END CERTIFICATE-----"
echo "$PINGAP_TLS_CERT" | tr '|' '\n' > "$CERT_FILE"
echo "$PINGAP_TLS_KEY" | tr '|' '\n' > "$KEY_FILE"

# Set secure permissions on key file
chmod 600 "$KEY_FILE"
chmod 644 "$CERT_FILE"

echo ""
echo "Certificate written to: $CERT_FILE"
echo "  First line: $(head -1 "$CERT_FILE")"
echo "  Last line:  $(tail -1 "$CERT_FILE")"
echo "  Line count: $(wc -l < "$CERT_FILE")"
echo ""
echo "Private key written to: $KEY_FILE"
echo "  First line: $(head -1 "$KEY_FILE")"
echo "  Last line:  $(tail -1 "$KEY_FILE")"
echo "  Line count: $(wc -l < "$KEY_FILE")"
echo ""

# Verify PEM format
if ! grep -q "BEGIN CERTIFICATE" "$CERT_FILE"; then
    echo "ERROR: Certificate does not appear to be valid PEM format!"
    echo "Content preview:"
    head -3 "$CERT_FILE"
    exit 1
fi

if ! grep -q "BEGIN PRIVATE KEY" "$KEY_FILE"; then
    echo "ERROR: Private key does not appear to be valid PEM format!"
    exit 1
fi

echo "Certificate and key PEM format validated successfully."
echo ""
echo "Using config file: $CONFIG_FILE"
echo ""
echo "========================================"
echo "Starting Pingap..."
echo "========================================"

# Start Pingap with our config file
exec pingap -c "$CONFIG_FILE" "$@"
