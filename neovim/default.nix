{ config, pkgs, lib, inputs, ... }:

with lib;

{
  config = {
    # 1. Enable Neovim in Home Manager
    programs.neovim = {
      enable = true;
      defaultEditor = true;
    };

    # 2. Install Neovim and AstroVim dependencies
    home.packages = with pkgs; [
      gcc
      unzip
      ripgrep  # For Telescope
      fd       # For Telescope
      nodejs   # Required by some LSPs / Mason
    ];

    # 3. Link AstroVim's configuration into ~/.config/nvim
    # This makes the contents of the AstroVim repo appear as ~/.config/nvim
     xdg.configFile."nvim" = {
      source = ./dotfiles/nvim; # Path relative to this neovim.nix file
      recursive = true; # Ensure the entire directory contents are linked
    };

    xdg.configFile."mcphub/servers.json" = {
      text = ''
      {
        "mcpServers": {
          "CodeMind": {
            "command": "/google/bin/releases/codemind-mcp-server/server.par",
            "timeout": 300000
          },
          "F1": {
            "command": "/google/bin/releases/f1-mcp-server/server.par",
            "timeout": 300000
          },
          "ProductionAgent": {
            "command": "/google/bin/releases/production-agent-mcp/mcp_server.par",
            "timeout": 300000
          }
        },
        "nativeMCPServers": {
          "mcphub": {
            "disabled": true
          },
          "neovim": {
            "disabled": true
          }
        }
      }
      '';
    };

    # AstroVim uses lazy.nvim internally to manage plugins.
    # By linking the config, Neovim will find AstroVim's init.lua
    # and bootstrap lazy.nvim and plugins on the first run.
  };
}
