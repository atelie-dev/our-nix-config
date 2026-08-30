# Harmonia binary cache server: serves this machine's /nix/store to the LAN.
# Imported by fabio-nixos only.
#
# The signing key lives at /var/lib/nix-cache/secret-key (root-owned, never
# committed to git). A key pair for this cache has already been generated;
# install the secret half with:
#   sudo mkdir -p /var/lib/nix-cache
#   sudo install -m 600 /tmp/opencode/nix-cache-secret-key /var/lib/nix-cache/secret-key
# If you prefer to generate a fresh pair instead, also update the public key
# in shared/binary-cache-client.nix:
#   sudo nix key generate-secret --key-name fabio-nixos-cache \
#     | sudo tee /var/lib/nix-cache/secret-key > /dev/null
#   sudo chmod 600 /var/lib/nix-cache/secret-key
#   nix key convert-secret-to-public < /var/lib/nix-cache/secret-key
# The matching public key is configured in shared/binary-cache-client.nix.
{
  services.harmonia.cache = {
    enable = true;
    signKeyPaths = [ "/var/lib/nix-cache/secret-key" ];
  };

  # Harmonia has no built-in firewall option; open its port explicitly.
  networking.firewall.allowedTCPPorts = [ 5000 ];
}