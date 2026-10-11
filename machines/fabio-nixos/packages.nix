{
  config,
  pkgs,
  inputs,
  ...
}:

{
  # OpenChamber trial (github:fabiob/openchamber feat-nix-flake, upstream PR
  # pending): the Electron desktop GUI in system packages plus the always-on
  # browser UI as a systemd service (127.0.0.1:3000, state under the user's
  # HOME, seeing the same projects/ssh/opencode config as a manual run).
  # The UI password file is created locally per machine (~/.config/openchamber/
  # ui-password, 0600) instead of sops, so rotating it needs no rebuild:
  # edit the file, then `systemctl restart openchamber`. A missing file fails
  # the service start by design (fail-closed) — create it before enabling.
  imports = [ inputs.openchamber.nixosModules.default ];
  services.openchamber = {
    enable = true;
    user = "fabio";
    uiPasswordFile = "/home/fabio/.config/openchamber/ui-password";
  };

  # Enables the GPaste clipboard manager
  programs.gpaste.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    # OpenChamber desktop GUI (trial)
    inputs.openchamber.packages.${pkgs.stdenv.hostPlatform.system}.openchamber-desktop

    # Generic GUI tools
    megasync # Easy automated syncing between your computers and your MEGA Cloud Drive
    morewaita-icon-theme # Adwaita style extra icons theme for Gnome Shell
    typora # Markdown editor, a markdown reader

    btrfs-progs # Utilities for the btrfs filesystem
    compsize # Find compression type/ratio on a file or set of files in the Btrfs filesystem
  ];

  # 1Password is configured in shared/onepassword.nix

  programs.steam = {
    enable = true;
  };

  programs.obs-studio = {
    enable = true;
    enableVirtualCamera = true;
  };

  # programs.thunderbird.enable = true;

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
