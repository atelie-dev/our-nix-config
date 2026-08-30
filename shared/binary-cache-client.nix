# Use fabio-nixos as an additional binary cache (Harmonia on port 5000).
# Imported by tania-nixos and marcel-nixos.
#
# nix.settings.substituters concatenates across modules, so the effective
# order is: nix-community, flox, fabio-nixos (LAN, fast), cache.nixos.org.
# Paths missing from the LAN cache fall through to the upstream caches.
{
  nix.settings.substituters = [ "http://fabio-nixos.local:5000" ];
  nix.settings.trusted-public-keys = [
    "fabio-nixos-cache:xGlq5sOwQc0CNq3BfJ0SpTrf8W31c8xjcic3N7ZW5BA="
  ];
}