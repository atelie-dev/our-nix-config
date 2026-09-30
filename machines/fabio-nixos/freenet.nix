{
  config,
  pkgs,
  ...
}:
{
  # Supervised, self-updating Freenet peer (freenet-node.service, user
  # `freenet`, state in /var/lib/freenet). Upstream docs:
  # https://freenet.org/nix/ and docs/nix.md in freenet-core.
  # Auto-update is on by default and must stay on — the node replaces its own
  # binary under /var/lib/freenet/bin, so the store path drifts from what runs.
  services.freenet-node = {
    enable = true;
    # Pin the peer port. The default is a random free port, which makes inbound
    # connections (and the UPnP mapping below) unpredictable.
    extraArgs = [
      "--network-port"
      "31337"
    ];
  };

  # Freenet's peer transport is UDP. Without this the peer only makes outbound
  # connections and contributes poorly to the network. (Harmonia's TCP 5000 is
  # opened in shared/binary-cache-server.nix; lists merge across modules.)
  networking.firewall.allowedUDPPorts = [ 31337 ];

  # Freenet does not request router port mappings itself (listed upstream as a
  # future enhancement, not on the roadmap), so maintain the UPnP mapping from
  # the host: ask the gateway to forward external UDP 31337 to this machine,
  # refreshed on a timer because mappings expire and the LAN IP can change
  # with DHCP. Requires UPnP enabled on the router; if it is not, upnpc fails
  # harmlessly and the node runs outbound-only.
  systemd.services.freenet-upnp = {
    description = "UPnP port mapping for the Freenet peer";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.miniupnpc}/bin/upnpc -r 31337 UDP";
    };
  };
  systemd.timers.freenet-upnp = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "1min";
      OnUnitActiveSec = "5min";
    };
  };
}
