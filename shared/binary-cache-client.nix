# Use fabio-nixos as the LAN binary cache (ncps on port 5000).
# Imported by tania-nixos and marcel-nixos.
#
# ncps is a transparent caching proxy: paths it doesn't have yet are
# fetched from the upstream caches (cache.nixos.org, nix-community,
# flox), stored on fabio-nixos, and served from the LAN afterwards.
# ?priority=10 ranks the LAN cache ahead of the direct upstream entries
# from base.nix, which remain as fallback while fabio-nixos is offline.
{
  nix.settings.substituters = [ "http://fabio-nixos.local:5000?priority=10" ];
  nix.settings.trusted-public-keys = [
    "fabio-nixos-cache:B9a0uep7wvq5H8BX9lf7vuVMSXvWO9h6am/7mMz8E84="
  ];
  # Bound connection attempts (incl. DNS) so an offline fabio doesn't stall
  # every path lookup; Nix then skips the cache and builds/falls through.
  nix.settings.connect-timeout = 5;
}
