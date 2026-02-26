{ pkgs, modulesPath, ... }:

{

  imports = [
    "${modulesPath}/virtualisation/google-compute-image.nix"
  ];
  # Minimal bootloader for VM
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";

  # Define a dummy root filesystem (required for NixOS evaluation)
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  networking.hostName = "nixos-vm";

  environment.systemPackages = with pkgs; [
    neovim
    git
    curl
  ];

  fonts.packages = with pkgs; [
    jetbrains-mono
  ];

  # Basic user configuration
  users.defaultUserShell = pkgs.zsh;
  users.users.nixos = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    initialPassword = "nixos";
  };

  users.users.tanmay = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    initialPassword = "tanmay";
  };
  users.users.tanmayvijay_google_com = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    initialPassword = "tanmay";
  };

  programs.zsh.enable = true;

  # Allow passwordless sudo for the wheel group
  security.sudo.wheelNeedsPassword = false;

  # Enable SSH for remote updates
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = true;
  };
  networking.firewall.allowedTCPPorts = [ 22 ];

  # Enable Flakes and new Nix command
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # System state version
  system.stateVersion = "24.11";

  # Ensure no GUI is enabled (default behavior, but being explicit)
  services.xserver.enable = false;
}
