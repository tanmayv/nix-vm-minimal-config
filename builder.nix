{ ... }:

{
  services.nix-serve = {
    enable = true;
    port = 8888;
    openFirewall = true;
    secretKeyFile = "/var/lib/nix-serve/cache-key.pem";
  };

}
