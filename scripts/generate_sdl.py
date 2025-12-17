#!/usr/bin/env python3
"""Generate SDL with TLS certificates from environment variables."""

import os
import re
import sys

def main():
    cert = os.environ.get('CLOUDFLARE_ORIGIN_CERT', '')
    key = os.environ.get('CLOUDFLARE_ORIGIN_KEY', '')
    image = os.environ.get('IMAGE', '')

    if not cert:
        print('WARNING: CLOUDFLARE_ORIGIN_CERT secret is empty!')
    if not key:
        print('WARNING: CLOUDFLARE_ORIGIN_KEY secret is empty!')

    # Read the SDL template
    with open('deploy-akash-ip-lease.yaml', 'r') as f:
        content = f.read()

    # Update the image tag (match either org name)
    content = re.sub(
        r'image: ghcr\.io/[^/]+/infrastructure-proxy-pingap:\S+',
        f'image: {image}',
        content
    )

    # Replace certificate placeholders
    # Certs are stored as raw PEM in secrets (with newlines)
    # Convert newlines to pipes for SDL (entrypoint.sh converts back with tr '|' '\n')
    cert_piped = cert.replace('\n', '|').strip('|')
    key_piped = key.replace('\n', '|').strip('|')

    content = content.replace('<REPLACE_WITH_ORIGIN_CERT>', cert_piped)
    content = content.replace('<REPLACE_WITH_ORIGIN_KEY>', key_piped)

    # Write the modified SDL
    with open('deploy-with-tls.yaml', 'w') as f:
        f.write(content)

    print(f'Generated SDL with image: {image}')
    print(f'Certificate length: {len(cert)} chars')
    print(f'Key length: {len(key)} chars')

if __name__ == '__main__':
    main()
