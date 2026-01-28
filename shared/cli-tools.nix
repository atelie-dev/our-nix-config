{ pkgs, ... }:
{
  # Sets vim as the default editor for all users
  environment.sessionVariables.EDITOR = "vim";

  environment.systemPackages = with pkgs; [
    # Development CLI
    bat # Cat(1) clone with syntax highlighting and Git integration
    devenv # Fast, Declarative, Reproducible, and Composable Developer Environments
    difftastic # Syntax-aware diff
    docker-buildx # Docker CLI plugin for extended build capabilities with BuildKit
    git # Distributed version control system
    gnumake # Tool to control the generation of non-source files from sources
    jq # Lightweight and flexible command-line JSON processor
    nixfmt # Official formatter for Nix code
    vim # Most popular clone of the VI editor
    yq-go # Portable command-line YAML processor

    # Other CLI
    age # Modern encryption tool with small explicit keys
    duf # Disk Usage/Free Utility
    dust # du + rust = dust. Like du but more intuitive
    ffmpeg_7 # Complete, cross-platform solution to record, convert and stream audio and video
    ripgrep # Utility that combines the usability of The Silver Searcher with the raw speed of grep
    eza # Modern, maintained replacement for ls
    psmisc # Set of small useful utilities that use the proc filesystem (such as fuser, killall and pstree)
    gnupg # Modern release of the GNU Privacy Guard, a GPL OpenPGP implementation
    comma # Runs programs without installing them
    broot # Interactive tree view, a fuzzy search, a balanced BFS descent and customizable commands
  ];
}
