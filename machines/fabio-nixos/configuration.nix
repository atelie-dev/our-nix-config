# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports = [
    ../../shared/base.nix
    ../../shared/cli-tools.nix
    ../../shared/gui-tools.nix
    ./hardware-configuration.nix
    ./nvidia.nix
    ./packages.nix
    ./virtualization.nix
    ../../shared/scripts.nix
    ../../shared/logitech.nix
    ../../shared/no-sleep.nix
    ../../shared/binary-cache-server.nix
  ];

  networking.hostName = "fabio-nixos"; # Define your hostname.
  networking.extraHosts = ''
    10.1.8.194 opera.santacasa.dominio qota.santacasa.dominio argocd.synnax.santacasa.dominio
  '';
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "altgr-intl";
  };

  # programs.niri.enable = true;
  # programs.yazi = {
  #   enable = true;
  #   plugins = {
  #     starship = pkgs.yaziPlugins.starship;
  #     wl-clipboard = pkgs.yaziPlugins.wl-clipboard;
  #     chmod = pkgs.yaziPlugins.chmod;
  #     git = pkgs.yaziPlugins.git;
  #   };
  # };
  # environment.systemPackages = with pkgs; [
  #   noctalia-shell
  #   xwayland-satellite
  #   tokyonight-gtk-theme
  #   swayimg
  #   rose-pine-cursor
  #   adwaita-icon-theme
  #   nemo
  #   fuzzel
  #   gpu-screen-recorder
  # ];
  # services.greetd = {
  #   enable = true;
  #   settings = {
  #     default_session = {
  #       command = "${pkgs.tuigreet}/bin/tuigreet --cmd niri-session";
  #       user = "greeter";
  #     };
  #   };
  # };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?
}
