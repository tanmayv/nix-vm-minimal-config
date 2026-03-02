{ pkgs, ... }:

{
  nix.settings = {
    # Replace with the actual IP or hostname of your VM
    substituters = [ "http://nixos-builder-test:8888" ];

    # Put the content of /var/lib/nix-serve/public-key.pem here
    trusted-public-keys = [ "my-vm-cache:Y7vErz9x7vIhSutAd3WN6/ke1Y9Vv74wpMQmHJFXZN4=" ];
  };

  systemd.services.nixos-generation-to-metadata = {
    enable = true;
    description = "Write NixOS generation info to GCP Metadata";
    path = [ pkgs.curl pkgs.nix pkgs.jq pkgs.coreutils pkgs.gnugrep pkgs.gawk ];
    script = ''
      set -euo pipefail

      # Get the list of generations, last 10
      GENERATIONS_INFO=$(nix-env --list-generations --profile /nix/var/nix/profiles/system | tail -n 10)

      JSON_PAYLOAD="[]"

      while read -r line; do
        if [ -z "$line" ]; then
          continue
        fi

        # Use awk to handle the variable spacing
        generation=$(echo "$line" | awk '{print $1}')
        date_str=$(echo "$line" | awk '{print $2, $3}')
        timestamp=$(date -d "$date_str" +%s)

        # Check if it's the current generation
        if echo "$line" | grep -q "(current)"; then
          active=1
          store_path=$(readlink -f /run/current-system)
        else
          active=0
          # The symlink is named like system-1-link, system-2-link, etc.
          store_path=$(readlink -f "/nix/var/nix/profiles/system-$generation-link")
        fi

        # Remove /nix/store prefix
        store_path_short=''${store_path#/nix/store/}

        # Create a JSON object for the current generation
        json_entry=$(jq -n \
          --arg generation "$generation" \
          --arg timestamp "$timestamp" \
          --argjson active "$active" \
          --arg store_path "$store_path_short" \
          '{generation: $generation, timestamp: $timestamp, active: $active, store_path: $store_path}')

        JSON_PAYLOAD=$(echo "$JSON_PAYLOAD" | jq --argjson entry "$json_entry" '. + [$entry]')

      done <<< "$GENERATIONS_INFO"

      curl -X PUT --data "$JSON_PAYLOAD" \
        "http://metadata.google.internal/computeMetadata/v1/instance/guest-attributes/nixos/generations" \
        -H "Metadata-Flavor: Google"
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
  };

  systemd.timers.nixos-generation-to-metadata = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "1m";
      OnUnitActiveSec = "1m";
      Unit = "nixos-generation-to-metadata.service";
    };
  };

  systemd.services.nixos-upgrade-from-metadata = {
    enable = true;
    description = "Upgrade NixOS from GCP Metadata";
    path = [ pkgs.curl pkgs.nix pkgs.openssh pkgs.gnugrep pkgs.coreutils pkgs.systemd ];

    script = ''
      # 1. Fetch the target store path from GCP Metadata
      TARGET_SYSTEM=$(curl -f -H "Metadata-Flavor: Google" \
        http://metadata.google.internal/computeMetadata/v1/instance/attributes/nix-store-path 2>/dev/null)

      if [ -z "$TARGET_SYSTEM" ]; then
        echo "No nix-store-path attribute found in metadata. Skipping."
        exit
      fi

      # 2. Check if we are already running this system
      CURRENT_SYSTEM=$(readlink -f /run/current-system)

      if [ "$TARGET_SYSTEM" == "$CURRENT_SYSTEM" ]; then
        # echo "System is already up to date ($CURRENT_SYSTEM). Skipping."
        OLD_HOSTNAME=$(hostnamectl --transient)

        # 5. Check if hostname changed and trigger reboot if needed
        NEW_HOSTNAME=$(hostnamectl --static)
        if [ "$OLD_HOSTNAME" != "$NEW_HOSTNAME" ]; then
          echo "Hostname changed from '$OLD_HOSTNAME' to '$NEW_HOSTNAME'. Rebooting..."
          systemctl reboot
        fi
        exit 0
      fi

      # 3. Copy the closure from the builder
      # NOTE: This requires SSH access to be configured for root@nixos-builder-test
      # You must add the root public key of this VM to /root/.ssh/authorized_keys on nixos-builder-test
      echo -e "\033[0;32mNEW UPDATE FOUND\033[0m"
      echo "Copying closure from builder..."
      nix copy --from http://nixos-builder-test:8888 "$TARGET_SYSTEM"

      # 4. Switch to the new configuration
      echo "Switching to new configuration..."
      nix-env -p /nix/var/nix/profiles/system --set $TARGET_SYSTEM

      systemd-run --no-block --unit="nixos-switcher-task" \
        "$TARGET_SYSTEM/bin/switch-to-configuration" switch

    '';

    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
  };

  systemd.timers.nixos-upgrade-from-metadata = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "1m";
      OnUnitActiveSec = "1m";
      Unit = "nixos-upgrade-from-metadata.service";
    };
  };
}
