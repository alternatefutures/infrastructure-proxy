#!/usr/bin/env node
/**
 * Update deployment registry after successful deployment
 *
 * Usage:
 *   node scripts/update-deployment-registry.js \
 *     --service "infrastructure-proxy" \
 *     --dseq "25312670" \
 *     --provider "akash1aaul837r7en7hpk9wv2svg8u78fdq0t2j2e82z" \
 *     --provider-name "DigitalFrontier" \
 *     --image "ghcr.io/alternatefutures/infrastructure-proxy-pingap:abc123" \
 *     --ip "77.76.13.213" \
 *     --commit-sha "$GITHUB_SHA"
 */

const fs = require('fs');
const path = require('path');

// Parse command line arguments
const args = process.argv.slice(2);
const params = {};
for (let i = 0; i < args.length; i += 2) {
  const key = args[i].replace(/^--/, '').replace(/-/g, '_');
  params[key] = args[i + 1];
}

const registryPath = path.join(__dirname, '..', 'deployments.json');
const registry = JSON.parse(fs.readFileSync(registryPath, 'utf8'));

// Find existing deployment for this service
const existingIndex = registry.deployments.findIndex(
  d => d.service === params.service
);

// Create new deployment record
const newDeployment = {
  service: params.service,
  dseq: params.dseq,
  provider: params.provider,
  providerName: params.provider_name || 'Unknown',
  owner: params.owner || 'akash1degudmhf24auhfnqtn99mkja3xt7clt9um77tn',
  dedicatedIP: params.ip || null,
  ingress: params.ingress || null,
  image: params.image,
  status: 'active',
  deployedAt: new Date().toISOString(),
  deployedBy: params.deployed_by || 'github-actions',
  commitSha: params.commit_sha,
  notes: params.notes || ''
};

// If there was a previous deployment, move it to history
if (existingIndex >= 0) {
  const oldDeployment = registry.deployments[existingIndex];
  registry.history.unshift({
    ...oldDeployment,
    status: 'closed',
    closedAt: new Date().toISOString(),
    closedReason: 'Replaced by new deployment'
  });
  registry.deployments[existingIndex] = newDeployment;
} else {
  registry.deployments.push(newDeployment);
}

// Write updated registry
fs.writeFileSync(registryPath, JSON.stringify(registry, null, 2) + '\n');

console.log('✅ Deployment registry updated');
console.log('Service:', params.service);
console.log('DSEQ:', params.dseq);
console.log('Provider:', params.provider_name || params.provider);
console.log('Image:', params.image);

// Output for GitHub Actions
if (process.env.GITHUB_OUTPUT) {
  fs.appendFileSync(
    process.env.GITHUB_OUTPUT,
    `deployment_recorded=true\n`
  );
}
