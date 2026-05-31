# Configuration related to the existing users and the home-manager configuration.

{
  inputs,
  lib,
  config,
  pkgs,
  ...
}:
{
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  nix.settings.trusted-users = [
    "root"
    "fabio"
  ];

  users.users.fabio = {
    isNormalUser = true;
    description = "Fábio Batista";
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
      "podman"
      "kvm"
    ];
    packages = with pkgs; [
      rtk # CLI proxy that reduces LLM token consumption by 60-90% on common dev commands
    ];
    subUidRanges = [
      {
        startUid = 100000;
        count = 65536;
      }
    ];
    subGidRanges = [
      {
        startGid = 100000;
        count = 65536;
      }
    ];
  };

  home-manager.useGlobalPkgs = true;
  home-manager.users.fabio =
    { pkgs, ... }:
    let
      defaultMonoFont = {
        name = "AdwaitaMono Nerd Font Regular";
        package = pkgs.nerd-fonts.adwaita-mono;
        size = 11;
      };
      flameshot-gui = pkgs.writeShellScriptBin "flameshot-gui" "${pkgs.flameshot}/bin/flameshot gui";
    in
    {
      imports = [ ./hm-opencode.nix ];

      home.packages = [ defaultMonoFont.package ];

      # Changes the default font
      fonts.fontconfig.enable = true;
      dconf.settings = {
        "org/gnome/desktop/interface" = {
          monospace-font-name = "${defaultMonoFont.name} ${toString defaultMonoFont.size}";
        };
      };

      # Enables fractional scaling
      dconf.settings = {
        "org/gnome/mutter" = {
          experimental-features = [
            "scale-monitor-framebuffer"
            "xwayland-native-scaling"
          ];
        };
      };

      # Adds flameshot as the default PtrScr keybinding
      dconf.settings = {
        # Disables the default screenshot interface
        "org/gnome/shell/keybindings" = {
          show-screenshot-ui = [ ];
        };
        # Sets the new keybindings
        "org/gnome/settings-daemon/plugins/media-keys" = {
          custom-keybindings = [
            "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
          ];
        };
        # Defines the new shortcut
        "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
          binding = "Print";
          command = "${flameshot-gui}/bin/flameshot-gui";
          name = "Flameshot";
        };
      };

      home.shell.enableShellIntegration = true;

      # Autostart some programs
      xdg.autostart = {
        enable = true;
        entries = [
          "${pkgs._1password-gui}/share/applications/1password.desktop"
        ];
      };

      programs = {
        bash = {
          enable = true;
        };

        broot.enable = true;
        broot.enableBashIntegration = true;

        fzf.enable = true;
        fzf.enableBashIntegration = true;

        mcfly.enable = true;
        mcfly.fzf.enable = true;
        mcfly.enableBashIntegration = true;
        mcfly.interfaceView = "BOTTOM";
        mcfly.keyScheme = "vim";
        mcfly.fuzzySearchFactor = 3;

        z-lua.enable = true;
        z-lua.enableBashIntegration = true;
        z-lua.options = [
          "enhanced"
          "echo"
        ];

        direnv = {
          enable = true;
          enableBashIntegration = true;
          nix-direnv.enable = true;
        };

        starship.enable = true;

        kitty = {
          enable = true;
          extraConfig = ''
            scrollback_lines 1000000
            scrollback_pager_history_size 100000
          '';
          keybindings = {
            "ctrl+shift+t" = "new_tab_with_cwd";
            "ctrl+shift+enter" = "launch --type=window --cwd=current";
            "ctrl+k" = "clear_terminal to_cursor_scroll active";
            "ctrl+shift+k" = "combine : clear_terminal scroll active : clear_terminal scrollback active";
          };
        };
      };

      services.podman = {
        enable = true;
        settings.policy = {
          default = [ { type = "insecureAcceptAnything"; } ];
          transports = {
            docker-daemon = {
              "" = [ { type = "insecureAcceptAnything"; } ];
            };
          };
        };
      };

      home.file."idea.properties".text =
        "idea.filewatcher.executable.path = ${pkgs.fsnotifier}/bin/fsnotifier";

      home.stateVersion = "25.05";
    };
}
