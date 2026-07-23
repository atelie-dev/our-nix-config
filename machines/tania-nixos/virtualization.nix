{ config, pkgs, ... }:
{
  # Docker
  virtualisation.docker = {
    enable = false;

    rootless = {
      enable = true;
      setSocketVariable = true;
      daemon.settings = {
        dns = [ "1.1.1.1" "1.0.0.1" "8.8.8.8" "8.8.4.4" ];
        registry-mirrors = [ "https://mirror.gcr.io" ];
      };
    };
  };

  boot.binfmt = {
    emulatedSystems = [ "aarch64-linux" "armv6l-linux" "armv7l-linux" ];
    preferStaticEmulators = true; # Essential for Docker
  };

  programs.virt-manager.enable = true;

  users.groups.libvirtd.members = ["tania"];
  users.users.tania.linger = true; # Essential for the user services to persist after logout

  virtualisation.libvirtd.enable = true;
  virtualisation.libvirtd.qemu.runAsRoot = false;
  virtualisation.spiceUSBRedirection.enable = true;

  home-manager.users.tania.dconf.settings = {
    "org/virt-manager/virt-manager/connections" = {
      autoconnect = ["qemu:///system"];
      uris = ["qemu:///system"];
    };
  };
}
