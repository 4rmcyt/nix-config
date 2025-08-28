#!/usr/bin/env bash

set -euo pipefail

HOST=${1:-homeserver}

case $HOST in
homeserver)
  echo "Deploying to NixOS homeserver..."
  sudo nixos-rebuild switch --flake .#homeserver | cachix push homeserver
  ;;
macbook)
  echo "Deploying to Darwin macbook..."
  darwin-rebuild switch --flake .#macbook | cachix push macbookk
  ;;
wsl)
  echo "Deploying to WSL2..."
  sudo nixos-rebuild switch --flake .#wsl
  ;;
*)
  echo "Unknown host: $HOST"
  echo "Usage: $0 [homeserver|macbook|wsl]"
  exit 1
  ;;
esac