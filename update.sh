#!/bin/bash

# Usage: ./update.sh [IP_ADDRESS] [EXTRA_ARGS...]
# Example: ./update.sh 192.168.64.2 --ask-sudo-password

TARGET_IP="${1:-192.168.64.2}"
shift

echo "Deploying to tanmay@$TARGET_IP..."

nix run nixpkgs#nixos-rebuild -- switch \
  --flake .#nixos-vm \
  --target-host "tanmay@$TARGET_IP" \
  --build-host "tanmay@$TARGET_IP" \
  --sudo "$@"
