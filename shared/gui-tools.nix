{ config, pkgs, ... }:

{
  # Install Chromium
  programs.chromium.enable = true;

  # Enables the Gnome Keyring
  programs.seahorse.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    # Generic GUI tools
    flameshot # Powerful yet simple to use screenshot software
    google-chrome # Freeware web browser developed by Google
    jetbrains-toolbox # Jetbrains Toolbox
    gimp3-with-plugins # GNU Image Manipulation Program
    inkscape-with-extensions # Vector graphics editor
    mission-center # Monitor your CPU, Memory, Disk, Network and GPU usage
    slack # Desktop client for Slack
    vscodium # Open source source code editor developed by Microsoft (VS Code without MS branding/telemetry/licensing)
    warp-terminal # Rust-based terminal

    # LibreOffice and OnlyOffice
    onlyoffice-desktopeditors
    libreoffice-stable # Comprehensive, professional-quality productivity suite, a variant of openoffice.org
    hunspell # Spell checker
    hunspellDicts.pt_BR # Hunspell dictionary for Portuguese (Brazil) from LibreOffice
    hunspellDicts.en_US # Hunspell dictionary for English (United States) from Wordlist
    hyphen # Text hyphenation library
    hyphenDicts.en_US
  ];

  programs.gnupg.agent.enable = true;

  # Mission Center: read Intel RAPL CPU power without root
  services.udev.extraRules = ''
    SUBSYSTEM=="powercap", KERNEL=="intel-rapl*", RUN+="${pkgs.coreutils}/bin/chmod a+r /sys/%p/energy_uj"
  '';

  # Mission Center: per-process network stats via nethogs without root
  security.wrappers.nethogs = {
    source = "${pkgs.nethogs}/bin/nethogs";
    owner = "root";
    group = "root";
    capabilities = "cap_net_admin,cap_net_raw,cap_dac_read_search,cap_sys_ptrace+pe";
  };
}
