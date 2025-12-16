/**
 * Cloudflare Worker: AlternateFutures Proxy Router
 *
 * This Worker acts as a full reverse proxy, routing custom domains directly
 * to their Akash backend services. This bypasses the Akash HTTP ingress
 * Host header limitation entirely.
 *
 * Flow:
 * 1. User → secrets.alternatefutures.ai
 * 2. Cloudflare → This Worker
 * 3. Worker → Directly to Europlots Infisical backend
 *
 * Benefits:
 * - No Host header issues (Worker rewrites Host to match backend)
 * - Cloudflare handles TLS termination
 * - Backend can be on any Akash provider
 * - Easy to update routes when deployments change
 */

// Domain → Backend configuration
// Update these when Akash deployments change (new dseq = new ingress URL)
const ROUTES = {
  // Secrets (Infisical) - Europlots DSEQ 24645907
  'secrets.alternatefutures.ai': {
    backend: 'https://v8c1fui9p1dah5m86ctithi5ok.ingress.europlots.com',
    host: 'v8c1fui9p1dah5m86ctithi5ok.ingress.europlots.com',
  },

  // Auth service - Europlots
  'auth.alternatefutures.ai': {
    backend: 'https://ubsm31q4ol97b1pi5l06iognug.ingress.europlots.com',
    host: 'ubsm31q4ol97b1pi5l06iognug.ingress.europlots.com',
  },

  // API service - gpu.subangle.com
  'api.alternatefutures.ai': {
    backend: 'https://rvknp4kjg598n8uslgnovkrdpk.ingress.gpu.subangle.com',
    host: 'rvknp4kjg598n8uslgnovkrdpk.ingress.gpu.subangle.com',
  },

  // Static sites via IPFS Gateway (Pinata)
  'app.alternatefutures.ai': {
    backend: 'https://gateway.pinata.cloud',
    host: 'gateway.pinata.cloud',
    pathPrefix: '/ipfs/QmU4VRKexpuA6RvYfXY9nUsgiHRMLDhxvZFi7ssGHn3aHj',
  },
  'alternatefutures.ai': {
    backend: 'https://gateway.pinata.cloud',
    host: 'gateway.pinata.cloud',
    pathPrefix: '/ipfs/QmU4VRKexpuA6RvYfXY9nUsgiHRMLDhxvZFi7ssGHn3aHj',
  },
  'www.alternatefutures.ai': {
    backend: 'https://gateway.pinata.cloud',
    host: 'gateway.pinata.cloud',
    pathPrefix: '/ipfs/QmU4VRKexpuA6RvYfXY9nUsgiHRMLDhxvZFi7ssGHn3aHj',
  },
  'docs.alternatefutures.ai': {
    backend: 'https://gateway.pinata.cloud',
    host: 'gateway.pinata.cloud',
    pathPrefix: '/ipfs/QmeQe1QuyiAiyCrJLASixPtH2VW6xQZxcpqCHJsUTtxfUR',
  },
};

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const originalHost = url.hostname;

    // Look up route configuration
    const route = ROUTES[originalHost];

    if (!route) {
      return new Response(JSON.stringify({
        error: 'Domain not configured',
        domain: originalHost,
        configured: Object.keys(ROUTES),
      }), {
        status: 404,
        headers: { 'Content-Type': 'application/json' }
      });
    }

    // Build backend URL
    const backendUrl = new URL(route.backend);
    backendUrl.pathname = (route.pathPrefix || '') + url.pathname;
    backendUrl.search = url.search;

    // Clone headers and set correct Host for backend
    const headers = new Headers(request.headers);
    headers.set('Host', route.host);
    headers.set('X-Forwarded-Host', originalHost);
    headers.set('X-Forwarded-Proto', 'https');
    headers.set('X-Real-IP', request.headers.get('CF-Connecting-IP') || '');

    // Remove Cloudflare-specific headers that might confuse backend
    headers.delete('CF-IPCountry');
    headers.delete('CF-RAY');
    headers.delete('CF-Visitor');

    try {
      const response = await fetch(backendUrl.toString(), {
        method: request.method,
        headers: headers,
        body: request.body,
        redirect: 'manual',
      });

      // Clone response headers
      const responseHeaders = new Headers(response.headers);

      // Add debug headers
      responseHeaders.set('X-Routed-Via', 'cf-worker');
      responseHeaders.set('X-Backend', route.backend);

      // Handle redirects - rewrite Location header to use original domain
      if (response.status >= 300 && response.status < 400) {
        const location = response.headers.get('Location');
        if (location) {
          try {
            const locationUrl = new URL(location);
            if (locationUrl.hostname === route.host) {
              locationUrl.hostname = originalHost;
              responseHeaders.set('Location', locationUrl.toString());
            }
          } catch (e) {
            // Relative redirect, leave as-is
          }
        }
      }

      return new Response(response.body, {
        status: response.status,
        statusText: response.statusText,
        headers: responseHeaders,
      });
    } catch (error) {
      return new Response(JSON.stringify({
        error: 'Backend connection failed',
        message: error.message,
        backend: route.backend,
      }), {
        status: 502,
        headers: { 'Content-Type': 'application/json' }
      });
    }
  },
};
