#!/usr/bin/env node
/**
 * Mark a deployment as closed in the registry
 *
 * Usage:
 *   node scripts/close-deployment.js --dseq "24758214" --reason "Out of funds"
 */

const fs = require('fs');
const path = require('path');

const args = process.argv.slice(2);
const params = {};
for (let i = 0; i < args.length; i += 2) {
  const key = args[i].replace(/^--/, '').replace(/-/g, '_');
  params[key] = args[i + 1];
}

if (!params.dseq) {
  console.error('❌ Error: --dseq is required');
  process.exit(1);
}

const registryPath = path.join(__dirname, '..', 'deployments.json');
const registry = JSON.parse(fs.readFileSync(registryPath, 'utf8'));

// Find the deployment
const index = registry.deployments.findIndex(d => d.dseq === params.dseq);

if (index === -1) {
  console.error(`❌ Error: Deployment ${params.dseq} not found in active deployments`);
  process.exit(1);
}

// Move to history
const deployment = registry.deployments[index];
registry.history.unshift({
  ...deployment,
  status: 'closed',
  closedAt: new Date().toISOString(),
  closedReason: params.reason || 'Manually closed'
});

registry.deployments.splice(index, 1);

// Write updated registry
fs.writeFileSync(registryPath, JSON.stringify(registry, null, 2) + '\n');

console.log('✅ Deployment marked as closed');
console.log('DSEQ:', params.dseq);
console.log('Service:', deployment.service);
console.log('Reason:', params.reason || 'Manually closed');
