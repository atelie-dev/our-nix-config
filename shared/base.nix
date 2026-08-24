{
  config,
  pkgs,
  inputs,
  ...
}:
{
  # Enables flakes and the nix command without the pesky experimental warnings
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Collect garbage automatically, every week
  nix.gc.automatic = true;
  nix.gc.dates = "weekly";

  # Deduplicate store files
  nix.settings.auto-optimise-store = true;

  # Keep store blobs for old generations up to 30 days
  nix.gc.options = "--delete-older-than 30d";

  # Adds several binary caches to speed up builds
  nix.settings = {
    substituters = [
      "https://nix-community.cachix.org"
      "https://cache.flox.dev"
    ];
    trusted-public-keys = [
      "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
      "flox-cache-public-1:7F4OyH7ZCnFhcze3fJdfyXYLQw/aV7GEed86nQ7IsOs="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  # Limit the number of generations to show on boot
  boot.loader.systemd-boot.configurationLimit = 10;

  # Reports updated packages after an upgrade
  system.activationScripts.diff = ''
    if [[ -e /run/current-system ]]; then
      ${pkgs.nix}/bin/nix store diff-closures /run/current-system "$systemConfig"
    fi
  '';

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Double inotify limits
  boot.kernel.sysctl = {
    "fs.inotify.max_queued_events" = 32768;
    "fs.inotify.max_user_instances" = 1048576;
    "fs.inotify.max_user_watches" = 1048576;
    "user.max_inotify_instances" = 1048576;
    "user.max_inotify_watches" = 1048576;
  };

  zramSwap.enable = true;
  boot.tmp.useZram = true;

  # Enable networking
  networking.networkmanager.enable = true;
  networking.networkmanager.insertNameservers = [
    "1.1.1.1"
    "8.8.8.8"
    "8.8.4.4"
  ];
  networking.networkmanager.connectionConfig."connection.mdns" = 2;
  networking.networkmanager.plugins = [
    pkgs.networkmanager-openconnect
  ];

  services.avahi.enable = true;
  services.resolved = {
    enable = true;
    settings.Resolve = {
      MulticastDNS = true;
    };
  };

  # Set your time zone.
  time.timeZone = "America/Sao_Paulo";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "pt_BR.UTF-8";
    LC_IDENTIFICATION = "pt_BR.UTF-8";
    LC_MEASUREMENT = "pt_BR.UTF-8";
    LC_MONETARY = "pt_BR.UTF-8";
    LC_NAME = "pt_BR.UTF-8";
    LC_NUMERIC = "pt_BR.UTF-8";
    LC_PAPER = "pt_BR.UTF-8";
    LC_TELEPHONE = "pt_BR.UTF-8";
    LC_TIME = "pt_BR.UTF-8";
  };

  # Configure console keymap
  console.useXkbConfig = true;

  # Configure iBus
  i18n.inputMethod = {
    enable = true;
    type = "ibus";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome = {
    enable = true;
    extraGSettingsOverrides = ''
      [org.gnome.mutter]
      experimental-features=['scale-monitor-framebuffer', 'xwayland-native-scaling']
    '';
  };

  # Use userborn instead of update-users-groups.pl for user management.
  # Avoids spurious "not applying UID change" warnings for gdm-greeter users
  # (see https://github.com/NixOS/nixpkgs/issues/525919).
  services.userborn.enable = true;

  # Enables Wayland support for Electron Apps
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  hardware.bluetooth.settings = {
    General = {
      Experimental = true;
      ControllerMode = "dual";
    };
  };

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc.lib
      zlib
    ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Allow some insecure packages
  nixpkgs.config.permittedInsecurePackages = [
    "pnpm-10.29.2"
  ];
}
