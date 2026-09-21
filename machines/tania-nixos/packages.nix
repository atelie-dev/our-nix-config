{ config, pkgs, ... }:

{
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
  ];

  # 1Password is configured in shared/onepassword.nix

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
}
