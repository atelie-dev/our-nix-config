{ config, pkgs, ... }:

{
  # Enables the GPaste clipboard manager
  programs.gpaste.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
  ];

  # 1Password
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "zerbin_b" ];
  };

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
}
