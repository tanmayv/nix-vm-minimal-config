# Minimal NixOS VM Configuration

This repository contains a minimal NixOS configuration optimized for virtual machines. It supports both `aarch64-linux` (e.g., Apple Silicon via UTM) and `x86_64-linux`.

## Features

- **Multi-Architecture Support**: Pre-configured for `aarch64-linux` and `x86_64-linux`.

- **Base System**: Minimal NixOS (No GUI).
- **Shell**: `zsh` with:
  - **Starship**: Modern, fast cross-shell prompt.
  - **Atuin**: Magically searchable shell history.
  - **Syntax Highlighting** & **Autosuggestions**.
- **Editor**: **Neovim** with a custom AstroVim-based configuration (located in `./neovim`).
- **Fonts**: **JetBrains Mono** installed system-wide.
- **Git**: Managed via Home Manager with pre-configured identity.
- **Remote Management**: SSH enabled with passwordless `sudo` for the `tanmay` user.

## Repository Structure

- `flake.nix`: Entry point for the flake-based configuration.
- `configuration.nix`: System-level NixOS settings.
- `home.nix`: User-level settings via Home Manager.
- `neovim/`: Custom Neovim configuration files.
- `update.sh`: Convenience script for remote deployment.

## Deployment Workflows

### 1. Push from Mac (Remote Deployment)

Ensure you have Nix installed on your Mac and SSH access to the VM.

```bash
# Basic update (uses default IP 192.168.64.2)
./update.sh

# Update a specific VM IP with first-time sudo password prompt
./update.sh 192.168.64.5 --ask-sudo-password
```

### 2. Build on a New VM (Bootstrap)

If you clone this repository directly inside a fresh NixOS VM:

1.  Install Git: `nix-shell -p git`
2.  Clone the repo: `git clone <repo-url>`
3.  Apply the configuration:
    ```bash
    # For ARM64 (Apple Silicon)
    sudo nixos-rebuild switch --flake .#nixos-vm-aarch64

    # For x86_64
    sudo nixos-rebuild switch --flake .#nixos-vm-x86_64
    ```

### 3. Deploy to a Brand New VM from Mac

If you have a fresh VM and want to push this config to it for the first time:

1.  Enable Flakes in the VM (if not already enabled):
    ```bash
    mkdir -p ~/.config/nix
    echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
    ```
2.  From your Mac, run:
    ```bash
    ./update.sh <VM_IP> --ask-sudo-password
    ```

## Post-Installation Notes

- **Default User**: `tanmay`
- **Default Password**: `nixos`
- **SSH Port**: 22
- **Shell**: The default shell is set to `zsh`. You may need to log out and back in for the shell change to take effect after the first deployment.
