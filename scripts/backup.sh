#!/bin/bash

# Automated backup script for NixOS homeserver
# This script should be run as root or with sudo

BACKUP_DATE=$(date +"%Y-%m-%d")
BACKUP_DIR="/mnt/backup"
SECRETS_BACKUP="${BACKUP_DIR}/secrets_${BACKUP_DATE}.yaml"
CONFIG_BACKUP="${BACKUP_DIR}/nixos_config_${BACKUP_DATE}.tar.gz"
LOG_FILE="${BACKUP_DIR}/backup_${BACKUP_DATE}.log"

# Ensure backup directory exists
mkdir -p "$BACKUP_DIR"

# Start logging
exec > >(tee -a "$LOG_FILE") 2>&1

echo "====================================="
echo "NixOS Homeserver Backup - ${BACKUP_DATE}"
echo "====================================="

# 1. Backup secrets
echo "Backing up secrets..."
cp /etc/nixos/secrets.yaml "$SECRETS_BACKUP"

# 2. Backup NixOS configuration
echo "Backing up NixOS configuration..."
tar -czf "$CONFIG_BACKUP" /etc/nixos

# 3. Backup important databases
echo "Backing up PostgreSQL databases..."
su - postgres -c "pg_dumpall" > "${BACKUP_DIR}/postgres_all_${BACKUP_DATE}.sql"

# 4. Backup specific service data
echo "Backing up service data..."

# Nextcloud data
if [ -d "/var/lib/nextcloud" ]; then
  echo "- Backing up Nextcloud data..."
  tar -czf "${BACKUP_DIR}/nextcloud_data_${BACKUP_DATE}.tar.gz" /var/lib/nextcloud
fi

# Home Assistant
if [ -d "/var/lib/hass" ]; then
  echo "- Backing up Home Assistant configuration..."
  tar -czf "${BACKUP_DIR}/hass_config_${BACKUP_DATE}.tar.gz" /var/lib/hass
fi

# Set proper permissions
chown -R root:root "$BACKUP_DIR"
chmod -R 600 "$BACKUP_DIR"

echo "\nBackup completed successfully!"
echo "Backup location: $BACKUP_DIR"
echo "Backup log: $LOG_FILE"
