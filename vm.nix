{
  nix.settings = {
    # Replace with the actual IP or hostname of your VM
    substituters = [ "http://nixos-builder-test" ];

    # Put the content of /var/lib/nix-serve/public-key.pem here
    trusted-public-keys = [ "my-vm-cache:cPpNmyxpbkq9rD26vaEdoAiVL/Dv5qzy8fM7QVJyndw=%" ];
  };
}
