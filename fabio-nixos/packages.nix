{ config, pkgs, ... }:

{
  # Enables the GPaste clipboard manager
  programs.gpaste.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    # Generic GUI tools
    megasync # Easy automated syncing between your computers and your MEGA Cloud Drive
    morewaita-icon-theme # Adwaita style extra icons theme for Gnome Shell
    vesktop # Alternate client for Discord with Vencord built-in
    slack # Desktop client for Slack
    typora # Markdown editor, a markdown reader
  ];

  # 1Password
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "fabio" ];
  };

  programs.steam = {
    enable = true;
  };

  programs.obs-studio = {
    enable = true;
    enableVirtualCamera = true;
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  #services.nix-serve = {
  #  enable = true;
  #  openFirewall = true;
  #  secretKeyFile = "/misc/nix-serve/cache-priv-key.pem";
  #};

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;
}
