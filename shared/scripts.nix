{ config, pkgs, ... }:

{

  environment.systemPackages = [
    (pkgs.writeShellApplication {
      name = "do-nixos-upgrade";
      runtimeInputs = [
        pkgs.nix-output-monitor
        pkgs.nixos-rebuild-ng
      ];
      text = ''
        set -exo pipefail
        cd /etc/nixos
        nix flake update
        ${pkgs.nixos-rebuild-ng}/bin/nixos-rebuild switch --flake ".#$(hostname)" -v --log-format internal-json "$@" |& ${pkgs.nix-output-monitor}/bin/nom --json
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
