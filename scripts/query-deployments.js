#!/usr/bin/env node
/**
 * Query deployment registry
 *
 * Usage:
 *   node scripts/query-deployments.js                    # List all active
 *   node scripts/query-deployments.js --service infisical  # Filter by service
 *   node scripts/query-deployments.js --dseq 25312670     # Find by DSEQ
 *   node scripts/query-deployments.js --history           # Show history
 */

const fs = require('fs');
const path = require('path');

const args = process.argv.slice(2);
const params = {};
for (let i = 0; i < args.length; i++) {
  if (args[i].startsWith('--')) {
    const key = args[i].replace(/^--/, '').replace(/-/g, '_');
    params[key] = args[i + 1] && !args[i + 1].startsWith('--') ? args[i + 1] : true;
    if (params[key] !== true) i++;
  }
}

const registryPath = path.join(__dirname, '..', 'deployments.json');
const registry = JSON.parse(fs.readFileSync(registryPath, 'utf8'));

function formatDeployment(d) {
  const lines = [
    `Service: ${d.service}`,
    `DSEQ: ${d.dseq}`,
    `Provider: ${d.providerName || d.provider}`,
    `Status: ${d.status}`,
  ];

  if (d.dedicatedIP) lines.push(`IP: ${d.dedicatedIP}`);
  if (d.ingress) lines.push(`Ingress: ${d.ingress}`);
  if (d.image) lines.push(`Image: ${d.image}`);
  if (d.deployedAt) lines.push(`Deployed: ${d.deployedAt}`);
  if (d.commitSha) lines.push(`Commit: ${d.commitSha.substring(0, 7)}`);
  if (d.closedAt) lines.push(`Closed: ${d.closedAt}`);
  if (d.closedReason) lines.push(`Reason: ${d.closedReason}`);
  if (d.notes) lines.push(`Notes: ${d.notes}`);

  return lines.join('\n  ');
}

let deployments = params.history ? registry.history : registry.deployments;

// Filter by service
if (params.service) {
  deployments = deployments.filter(d => d.service === params.service);
}

// Filter by DSEQ
if (params.dseq) {
  deployments = deployments.filter(d => d.dseq === params.dseq);
}

// Display
if (deployments.length === 0) {
  console.log('No deployments found');
} else {
  console.log(`Found ${deployments.length} deployment(s):\n`);
  deployments.forEach((d, i) => {
    console.log(`[${i + 1}]`);
    console.log('  ' + formatDeployment(d));
    console.log();
  });
}

// Output JSON if requested
if (params.json) {
  console.log(JSON.stringify(deployments, null, 2));
}
