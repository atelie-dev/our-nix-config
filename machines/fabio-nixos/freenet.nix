{
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
    # connections unpredictable.
    extraArgs = [
      "--network-port"
      "31337"
    ];
  };

  # Freenet's peer transport is UDP. Without this the peer only makes outbound
  # connections and contributes poorly to the network. (Harmonia's TCP 5000 is
  # opened in shared/binary-cache-server.nix; lists merge across modules.)
  # Inbound reachability relies on a static port-forward on the router
  # (UDP 31337 -> this host, NAT -> Port Forwarding): the ISP firmware has no
  # UPnP, so there is no point maintaining a mapping from here.
  networking.firewall.allowedUDPPorts = [ 31337 ];
}
