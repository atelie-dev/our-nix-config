{ config, pkgs, ... }:

{

  environment.systemPackages = [
    (pkgs.writeShellApplication {
      name = "do-nixos-upgrade";
      runtimeInputs = [
        pkgs.nix
        pkgs.nix-output-monitor
        pkgs.nixos-rebuild-ng
      ];
      text = ''
        set -exo pipefail
        cd /etc/nixos

        recreate_lock=false
        args=()
        for arg in "$@"; do
          if [[ "$arg" == "--recreate-lock-file" || "$arg" == "-u" ]]; then
            recreate_lock=true
          else
            args+=("$arg")
          fi
        done

        if [[ "$recreate_lock" == "true" ]]; then
          nix flake update
        fi

        ${pkgs.nixos-rebuild-ng}/bin/nixos-rebuild switch --flake ".#$(hostname)" -v --log-format internal-json "''${args[@]}" |& ${pkgs.nix-output-monitor}/bin/nom --json
      '';
    })

    (
      let
        python = (pkgs.python314.withPackages (python-pkgs: [ python-pkgs.lxml ]));
      in
      pkgs.writeShellApplication {
        name = "do-update-jetbrains-jdbc";
        runtimeInputs = [ python ];
        text = ''
          ${python}/bin/python ${./scripts/jetbrains-update-jdbc.py}
        '';
      }
    )
  ];
}
