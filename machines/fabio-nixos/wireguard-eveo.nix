# WireGuard admin VPN — EVEO (gateway-2, 177.104.129.225:51820)
#
# Túnel para a rede interna 192.168.100.0/24 (pve hosts, CPs, workers) e
# para o DNAT do k8s API (10.99.0.1:6443 → 192.168.100.19:6443 no gateway).
# Chave privada em /home/fabio/wg/eveo-admin.key (0600, fora do git —
# gerada no gateway-2 via ansible, role eveo/gateways/roles/wireguard).
#
# Os DNATs públicos de gerência (8006/2222/6443 no gateway) foram removidos;
# TODO acesso admin passa por este túnel.
#
# Chave privada via sops-nix (secrets/wireguard-eveo.yaml — recipients:
# fabio + a chave age do HOST, derivada de /etc/ssh/ssh_host_ed25519_key).
{ inputs, config, ... }:

{
  imports = [ inputs.sops-nix.nixosModules.default ];

  sops.secrets."eveo_wg_private_key" = {
    sopsFile = ../../secrets/wireguard-eveo.yaml;
  };

  environment.systemPackages = [ pkgs.wireguard-tools ];

  networking.wireguard.interfaces.eveo-admin = {
    ips = [ "10.99.0.2/32" ];
    privateKeyFile = config.sops.secrets."eveo_wg_private_key".path;
    peers = [
      {
        # gateway-2 (server.pub gerado pelo role wireguard)
        publicKey = "eCxImOQRfLeBZLyupsTuUnl4Nj9Q/lIa7kysF4weeSo=";
        endpoint = "177.104.129.225:51820";
        allowedIPs = [
          "10.99.0.0/24"
          "192.168.100.0/24"
        ];
        persistentKeepalive = 25;
      }
    ];
  };

  # k8s API via túnel — gateway-2 DNAT wg0:6443 → 192.168.100.19:6443
  networking.extraHosts = ''
    10.99.0.1 k8s.eveo.consyste.com.br
  '';
}
