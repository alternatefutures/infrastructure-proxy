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

    # Update the image tag
    content = re.sub(
        r'image: ghcr\.io/wonderwomancode/infrastructure-proxy-pingap:\S+',
        f'image: {image}',
        content
    )

    # Replace certificate placeholders
    # Certs are pipe-delimited in secrets, convert to \n escape sequences
    cert_escaped = cert.replace('|', '\\n')
    key_escaped = key.replace('|', '\\n')

    content = content.replace('<REPLACE_WITH_ORIGIN_CERT>', cert_escaped)
    content = content.replace('<REPLACE_WITH_ORIGIN_KEY>', key_escaped)

    # Write the modified SDL
    with open('deploy-with-tls.yaml', 'w') as f:
        f.write(content)

    print(f'Generated SDL with image: {image}')
    print(f'Certificate length: {len(cert)} chars')
    print(f'Key length: {len(key)} chars')

if __name__ == '__main__':
    main()
