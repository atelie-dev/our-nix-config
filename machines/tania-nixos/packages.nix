{
  config,
  pkgs,
  inputs,
  ...
}:

{
  # OpenChamber trial (github:fabiob/openchamber feat-nix-flake, upstream PR
  # pending): the Electron desktop GUI in system packages and the server as
  # a systemd service on 127.0.0.1:3000 (state in /var/lib/openchamber).
  # Remove this block (or set services.openchamber.enable = false) to stop
  # the trial; the flake input stays harmless either way.
  imports = [ inputs.openchamber.nixosModules.default ];
  services.openchamber.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    # OpenChamber desktop GUI (trial)
    inputs.openchamber.packages.${pkgs.stdenv.hostPlatform.system}.openchamber-desktop
  ];

  # 1Password is configured in shared/onepassword.nix

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
}
