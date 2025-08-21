#!/usr/bin/env bash

set -euo pipefail

git pull

# --- CONFIGURATION ---
readonly INSTALLER_USER="root"
readonly TARGET_USER="zeev"
readonly REMOTE_HOST="192.168.1.165"
readonly HOSTNAME="homeserver"
readonly TARGET_HOST="${INSTALLER_USER}@${REMOTE_HOST}"

readonly NIX_FLAKE="github:4rmcyt/nix-config"
# The SSH URL for your secrets repository.
readonly SECRETS_GIT_REPO="git@github.com:4rmcyt/nix-secrets-repo.git"
# The local path to the SSH key that can clone the secrets repo.
readonly LOCAL_GIT_SSH_KEY="${HOME}/.ssh/zeev"
# IMPORTANT: The local path to the private age key for the HOMESERVER.
readonly LOCAL_HOMESERVER_AGE_KEY="${HOME}/.config/sops/age/age.key"

readonly REMOTE_SOPS_KEY_PATH="/var/lib/sops/age.key"
readonly REMOTE_SSH_DIR="/mnt/home/${TARGET_USER}/.ssh"

# --- SCRIPT LOGIC ---
echo "### Starting NixOS Installation for ${TARGET_HOST} ###"
echo ">>> Using Git-based secrets workflow."

# --- 1. Pre-flight Checks ---
if ! command -v nixos-anywhere &>/dev/null; then
  echo "[ERROR] 'nixos-anywhere' not found."
  exit 1
fi
if [[ ! -f ${LOCAL_HOMESERVER_AGE_KEY} ]]; then
  echo "[ERROR] Homeserver age key not found at: ${LOCAL_HOMESERVER_AGE_KEY}"
  exit 1
fi
if [[ ! -f ${LOCAL_GIT_SSH_KEY} ]]; then
  echo "[ERROR] Git SSH deploy key not found at: ${LOCAL_GIT_SSH_KEY}"
  exit 1
fi
if ! ssh -o ConnectTimeout=5 "${TARGET_HOST}" "sudo -n true"; then
  echo "[ERROR] Could not connect to ${TARGET_HOST} as user '${INSTALLER_USER}' or user lacks passwordless sudo."
  exit 1
fi
echo ">>> All checks passed."

# --- 2. Clean Up Previous Run ---
echo ">>> Cleaning up temporary files from previous runs on remote..."
ssh "${TARGET_HOST}" "rm -rf /tmp/age.key /tmp/git_deploy_key /tmp/secrets"

# --- 3. Bootstrap Secrets ---
echo ">>> Copying bootstrap secrets to remote..."
scp -q "${LOCAL_HOMESERVER_AGE_KEY}" "${TARGET_HOST}:/tmp/age.key"
scp -q "${LOCAL_GIT_SSH_KEY}" "${TARGET_HOST}:/tmp/git_deploy_key"

# --- 4. Main Remote Execution ---
echo ">>> Starting remote setup..."
# shellcheck disable=SC2087
ssh "${TARGET_HOST}" sudo bash <<EOF
set -e
nix-env -iA nixos.git nixos.sops nixos.openssh

mkdir -p /root/.ssh
mv /tmp/git_deploy_key /root/.ssh/zeev # <-- This is the corrected line
chmod 600 /root/.ssh/zeev
ssh-keyscan github.com >> /root/.ssh/known_hosts

GIT_SSH_COMMAND="ssh -i /root/.ssh/zeev" git clone '${SECRETS_GIT_REPO}' /tmp/secrets

export SOPS_AGE_KEY_FILE=/tmp/age.key

mkdir -p "$(dirname "${REMOTE_SOPS_KEY_PATH}")"
mkdir -p "${REMOTE_SSH_DIR}"


sops -d /tmp/secrets/ssh/id_ed25519 > "${REMOTE_SSH_DIR}/id_ed25519"
sops -d /tmp/secrets/ssh/id_rsa > "${REMOTE_SSH_DIR}/id_rsa"
sops -d /tmp/secrets/ssh/authorized_keys > "${REMOTE_SSH_DIR}/authorized_keys"
sops -d /tmp/secrets/ssh/zeev > "${REMOTE_SSH_DIR}/zeev"

mv /tmp/age.key "${REMOTE_SOPS_KEY_PATH}"
chown -R root:root "$(dirname ${REMOTE_SOPS_KEY_PATH})"
chmod 600 "${REMOTE_SOPS_KEY_PATH}"
chown -R 1000:100 "${REMOTE_SSH_DIR}"
chmod 700 "${REMOTE_SSH_DIR}"
chmod 600 "${REMOTE_SSH_DIR}/id_ed25519"
chmod 600 "${REMOTE_SSH_DIR}/id_rsa"
chmod 600 "${REMOTE_SSH_DIR}/zeev"
chmod 644 "${REMOTE_SSH_DIR}/authorized_keys"

rm -rf /tmp/secrets
EOF
echo ">>> Remote setup finished successfully."

# --- 5. Install NixOS ---
echo "###
### READY TO INSTALL NIXOS
###"

nixos-anywhere --build-on remote \
  --show-trace \
  --flake "${NIX_FLAKE}#${HOSTNAME}" \
  "$@" \
  "${TARGET_HOST}"
echo "###
### NixOS installation command finished.
###"
