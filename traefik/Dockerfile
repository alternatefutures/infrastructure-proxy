FROM traefik:v3.2

# Copy configuration files
COPY traefik.yaml /etc/traefik/traefik.yaml
COPY routes.yaml /etc/traefik/routes.yaml
COPY entrypoint.sh /entrypoint.sh

# Create directories for certs
RUN mkdir -p /etc/traefik/certs

# Make entrypoint executable
RUN chmod +x /entrypoint.sh

EXPOSE 443 8080

ENTRYPOINT ["/entrypoint.sh"]
