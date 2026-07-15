{
  lib,
  pkgs,
  config,
  ...
}:
{
  # The opencode-plugin-ast-lsp looks for binary "sg" in its own cache
  # (~/.cache/opencode-plugin-ast-lsp/bin/sg), not the system PATH.
  # On NixOS "sg" is the shadow-utils group switch command, so we
  # symlink the Nix-installed ast-grep into that cache directory.
  home.activation.populateAstGrepCache = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    cache_dir="${config.home.homeDirectory}/.cache/opencode-plugin-ast-lsp/bin"
    mkdir -p "$cache_dir"
    ln -sf "${pkgs.ast-grep}/bin/ast-grep" "$cache_dir/sg"
  '';

  sops = {
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
    defaultSopsFile = ./../secrets/firecrawl.yaml;
    secrets.firecrawl_api_key = {};
  };

  programs.opencode = {
    enable = true;
    extraPackages = [
      pkgs.nodejs_24
    ];
    context = ''
      # General rules

      Never interact directly with Git. Orient and ask the user to perform commits or any other git operation.

      When writing or suggesting new code, evaluate the effort using the skill `evaluate-new-dep`.

      ## NixOS environment

      Always remember we're running on a NixOS environment. This means:

      * If a command does not exist, it can be run with `devenv shell`, the "comma" command, or `nix-shell -p`.
      * If a file is not writable, stop and ask how to proceed.
      * There's a nixos MCP running for anything NixOS related.
    '';
    skills = {
      evaluate-new-dep = ''
        ---
        name: evaluate-new-dep
        description: Decide between including a new dependency or writing code directly.
        ---

        # Instructions
        - Search for an existing library or package required to write new code.
        - Always suggest the most recent version.
        - Assess and report on the package quality, popularity and activity.
        - Compare with the effort, risk and advantages of implementing the funcionality directly on the code.
      '';
    };
    settings = {
      default_agent = "OpenCoder";
      plugin = [
        "@simonwjackson/opencode-direnv"
        "opencode-plugin-ast-lsp"
        "@angdrew/opencode-hashline-plugin"
      ];
      model = "ollama-cloud/deepseek-v4-flash";
      agent = {
        build = {
          model = "ollama-cloud/deepseek-v4-flash";
          variant = "high";
        };
        plan = {
          model = "ollama-cloud/glm-5.2";
        };
        explore = {
          mode = "subagent";
          permission = {
            edit = "deny";
            write = "deny";
          };
          prompt = ''
            You are a codebase exploration agent. Your task is to analyze the code structure.
            When searching for patterns, function definitions, or class usages, use the `ast_grep_search` tool
            to find them based on syntax trees, not just text. This will give more accurate results.
            Do not make any edits.
          '';
        };
      };
      provider = {
        ollama = {
          name = "Ollama";
          npm = "@ai-sdk/openai-compatible";
          options = {
            baseURL = "http://127.0.0.1:11434/v1";
          };
        };
      };
      lsp = {
        pyrefly = {
          enabled = true;
          command = [
            "uvx"
            "pyrefly"
            "lsp"
          ];
          extensions = [
            ".py"
            ".pyi"
          ];
        };
      };
      mcp = {
        atlassian = {
          type = "remote";
          url = "https://mcp.atlassian.com/v1/mcp/authv2";
          enabled = false;
        };
        nixos = {
          type = "local";
          command = [ "mcp-nixos" ];
          enabled = true;
        };
        firebase-mcp-server = {
          type = "local";
          command = [
            "firebase"
            "mcp"
          ];
          enabled = false;
        };
        firecrawl = {
          type = "remote";
          url = "https://mcp.firecrawl.dev/v2/mcp";
          enabled = true;
          headers = {
            Authorization = "Bearer {file:${config.home.homeDirectory}/.config/sops-nix/secrets/firecrawl_api_key}";
          };
          oauth = false;
        };
      };
    };
  };
}
