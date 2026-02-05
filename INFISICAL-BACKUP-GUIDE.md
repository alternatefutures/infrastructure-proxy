# Infisical Database Backup Guide

## Overview

The Infisical deployment includes an automated backup container that:
- Runs `pg_dump` every 6 hours
- Keeps the last 10 backups
- Serves backups via HTTP on port 8000
- Stores backups in a persistent 5Gi volume

## Accessing Backups

### Method 1: Download via HTTP

Once deployed with the backup container, backups are available at:
```
http://<backup-service-ingress>:8000/
```

You'll see a list of backup files like:
- `infisical_backup_20260202_120000.sql.gz`
- `infisical_backup_20260202_180000.sql.gz`
- etc.

### Method 2: Manual Backup Trigger

Use the Akash MCP exec-command (when working) to trigger a manual backup:

```bash
mcp__akash__exec-command with:
  service: backup
  command: /backup.sh
```

### Method 3: Download Script

Use this script to automatically download the latest backup:

```bash
#!/bin/bash
# download-latest-backup.sh

BACKUP_URL="http://<backup-ingress>:8000"
LATEST=$(curl -s $BACKUP_URL | grep -oE 'infisical_backup_[0-9_]+\.sql\.gz' | sort -r | head -1)

if [ -n "$LATEST" ]; then
  echo "Downloading: $LATEST"
  curl -O "$BACKUP_URL/$LATEST"
  echo "Backup saved: $LATEST"
else
  echo "No backups found"
fi
```

## Restoring from Backup

To restore a backup to a new Infisical deployment:

```bash
# 1. Download and extract backup
gunzip infisical_backup_YYYYMMDD_HHMMSS.sql.gz

# 2. Restore to postgres (use exec-command or direct access)
PGPASSWORD="<INFISICAL_DB_PASSWORD>" psql \
  -h <postgres-host> \
  -U infisical \
  -d infisical \
  < infisical_backup_YYYYMMDD_HHMMSS.sql
```

## Backup Schedule

- **Frequency**: Every 6 hours
- **Retention**: Last 10 backups (kept automatically)
- **Initial backup**: Runs immediately on container start

## Monitoring Backups

Check backup logs:
```bash
mcp__akash__get-logs with:
  service: backup
  tail: 50
```

## Storage Requirements

- Each backup: ~1-10 MB (depending on data)
- 10 backups: ~10-100 MB
- Volume size: 5 Gi (plenty of room)

## Updating Deployment to Include Backups

To add the backup container to your existing deployment:

1. Use the `infisical-akash-with-backup.yaml` SDL
2. This requires a NEW deployment (can't add services to existing)
3. Follow the same process as before:
   - Close old deployment
   - Create new deployment with backup SDL
   - Update proxy configuration
   - Update DNS if needed

## Alternative: External Backup Service

If you prefer external backups, you can:
1. Set up a GitHub Actions workflow to pull backups
2. Store in GitHub Artifacts, S3, or IPFS
3. Use the HTTP endpoint to automate downloads

## Security Note

The backup HTTP server is accessible via the public ingress. For production:
- Add authentication to the HTTP server
- Use HTTPS/TLS
- Or restrict access via firewall rules
