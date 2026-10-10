# ncps binary cache: the single LAN cache, served on port 5000.
# Imported by fabio-nixos only.
#
# ncps replaced harmonia (2026-10-10). Unlike harmonia, which could only
# serve paths already in /nix/store, ncps is a transparent caching proxy:
# on a miss it fetches from the upstream caches below, stores the result
# on disk (/var/lib/ncps), and serves LAN clients from then on.
#
# Signing key: pre-generated pair named fabio-nixos-cache. Install the
# secret half with:
#   sudo mkdir -p /var/lib/ncps
#   sudo install -m 600 /tmp/opencode/ncps-secret-key /var/lib/ncps/secret-key
# The public half is configured in shared/binary-cache-client.nix; ncps
# also serves it at http://<host>:5000/pubkey.
{ config, pkgs, ... }:

{
  services.ncps = {
    enable = true;

    # Same port harmonia used, so clients only need a key swap.
    server.addr = ":5000";

    cache = {
      hostName = "fabio-nixos-cache";
      secretKeyPath = "/var/lib/ncps/secret-key";

      # Bound the on-disk cache; nightly LRU trim keeps it under maxSize.
      maxSize = "100G";
      lru.schedule = "0 4 * * *";
      lru.scheduleTimeZone = "America/Sao_Paulo";

      # Sign everything we serve with our own key; upstream signatures are
      # verified on the way in via upstream.publicKeys.
      signNarinfo = true;

      # Accept pushes from this machine's post-build-hook (below).
      allowPutVerb = true;

      upstream = {
        urls = [
          "https://cache.nixos.org"
          "https://nix-community.cachix.org"
          "https://cache.flox.dev"
        ];
        publicKeys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "flox-cache-public-1:7F4OyH7ZCnFhcze3fJdfyXYLQw/aV7GEed86nQ7IsOs="
        ];
      };
    };
  };

  # Push every path built on this machine into the LAN cache so the other
  # machines can fetch it. Best-effort: a cache outage must never fail a
  # build. ncps signs on serve (signNarinfo), so no client-side signing
  # key is needed here.
  nix.settings.post-build-hook =
    let
      pushHook = pkgs.writeShellScript "push-to-lan-cache" ''
        if ! ${config.nix.package}/bin/nix copy --to http://127.0.0.1:5000 "$OUT_PATHS"; then
          echo "push-to-lan-cache: nix copy failed (LAN cache down?)" >&2
        fi
      '';
    in
    pushHook;

  # ncps has no built-in firewall option; open its port explicitly.
  networking.firewall.allowedTCPPorts = [ 5000 ];
}
