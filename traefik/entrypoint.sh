#!/bin/sh
set -e

# Write TLS certificate from environment variables
if [ -n "$TLS_CERT" ]; then
    echo "Writing TLS certificate..."
    echo "$TLS_CERT" | tr '|' '\n' > /etc/traefik/certs/origin.crt
fi

if [ -n "$TLS_KEY" ]; then
    echo "Writing TLS private key..."
    echo "$TLS_KEY" | tr '|' '\n' > /etc/traefik/certs/origin.key
    chmod 600 /etc/traefik/certs/origin.key
fi

# Verify certificates exist
if [ ! -f /etc/traefik/certs/origin.crt ] || [ ! -f /etc/traefik/certs/origin.key ]; then
    echo "ERROR: TLS certificates not found!"
    echo "Please set TLS_CERT and TLS_KEY environment variables"
    exit 1
fi

echo "Starting Traefik..."
exec traefik --configFile=/etc/traefik/traefik.yaml
