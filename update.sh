#!/bin/bash

# Usage: ./update.sh [IP_ADDRESS] [TARGET_NAME] [EXTRA_ARGS...]
# Example: ./update.sh 192.168.64.2 nixos-vm-x86_64 --ask-sudo-password

TARGET_IP="${1:-192.168.64.2}"
[ $# -gt 0 ] && shift

if [[ $1 == nixos-vm* ]]; then
  TARGET_NAME="$1"
  [ $# -gt 0 ] && shift
else
  TARGET_NAME="nixos-vm"
fi

echo "Deploying $TARGET_NAME to tanmay@$TARGET_IP..."

nix run nixpkgs#nixos-rebuild -- switch \
  --flake ".#$TARGET_NAME" \
  --target-host "tanmay@$TARGET_IP" \
  --build-host "tanmay@$TARGET_IP" \
  --sudo "$@"
