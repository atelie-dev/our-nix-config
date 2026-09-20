{
  lib,
  pkgs,
  config,
  ...
}:
let
  bun_1_3_13 = pkgs.bun.overrideAttrs (old: rec {
    version = "1.3.13";
    src = pkgs.fetchurl {
      url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-linux-x64-baseline.zip";
      hash = "sha256-nYokKSpwaAkCBdqsCloiP19pc29Sh+N7+I07QDHtx1A=";
    };
  });
  opencode_bun_1_3_13 = pkgs.opencode.override { bun = bun_1_3_13; };
in
{
  sops = {
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
    defaultSopsFile = ./../secrets/firecrawl.yaml;
    secrets.firecrawl_api_key = { };
    # Ollama Cloud API key for the second provider account, stored in its
    # own SOPS-encrypted file and read via {file:...} interpolation.
    # The primary `ollama-cloud` provider is left untouched and keeps using
    # the key stored in ~/.local/share/opencode/auth.json via /connect.
    secrets.ollama_cloud_api_key = {
      sopsFile = ./../secrets/ollama-cloud.yaml;
    };
    # Z.ai Coding Plan API key, stored in its own SOPS-encrypted file and
    # read via {file:...} interpolation. The Coding Plan endpoint is billed
    # separately from the general Z.ai API balance, so it needs its own key
    # and the dedicated /coding/paas/v4 baseURL.
    secrets.zai_api_key = {
      sopsFile = ./../secrets/zai.yaml;
    };
  };

  programs.opencode = {
    enable = true;
    package = opencode_bun_1_3_13;
    extraPackages = [
      pkgs.nodejs_24
      # AST-aware code search/replace CLI, used directly via bash by agents
      # (structural refactors that plain grep cannot express).
      pkgs.ast-grep
      # Bash LSP for opencode (.sh/.bash/.zsh/.ksh) — built-in server that
      # activates when the binary is on PATH.
      pkgs.bash-language-server
      # Shellcheck diagnostics are surfaced through the bash LSP when
      # shellcheck is available.
      pkgs.shellcheck
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
        "@angdrew/opencode-hashline-plugin"
      ];
      model = "ollama-cloud/deepseek-v4-flash";
      agent = {
        build = {
          model = "ollama-cloud/deepseek-v4-flash";
          variant = "high";
          options.fallback = [
            "deepseek/deepseek-v4-flash"
            "openrouter/nvidia/nemotron-3-super-120b-a12b:free"
          ];
        };
        plan = {
          model = "ollama-cloud/glm-5.3";
          options.fallback = [
            "opencode-go/glm-5.3"
            "zai-coding-plan/glm-5.3"
            "ollama-cloud/glm-5.3-flash"
            "opencode-go/glm-5.3-flash"
            "neuralwatt/glm-5.3-flash"
            "openrouter/deepseek/deepseek-v4.1-flash"
            "ollama-cloud/deepseek-v4-flash"
            "deepseek/deepseek-v4-pro"
          ];
        };
        explore = {
          mode = "subagent";
          options.fallback = [
            "deepseek/deepseek-v4-flash"
            "openrouter/nvidia/nemotron-3-super-120b-a12b:free"
          ];
          permission = {
            edit = "deny";
            write = "deny";
          };
          prompt = ''
            You are a codebase exploration agent. Your task is to analyze the code structure.
            When searching for patterns, function definitions, or class usages, use the `ast-grep` CLI
            via bash (e.g. `ast-grep run -p 'pattern' --json`) to find them based on syntax trees,
            not just text. This will give more accurate results.
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
        # Z.ai Coding Plan — uses the dedicated /coding/paas/v4 endpoint,
        # which is billed against the Coding Plan subscription quota rather
        # than the general pay-as-you-go API balance. The provider ID
        # `zai-coding-plan` matches the models.dev catalog, which auto-
        # discovers all available models (glm-4.7, glm-5-turbo, glm-5.2,
        # glm-5.2-highspeed, glm-5.3, glm-5.3-highspeed, glm-5.3-flash).
        # Only the API key needs to be supplied.
        zai-coding-plan = {
          options = {
            apiKey = "{file:${config.home.homeDirectory}/.config/sops-nix/secrets/zai_api_key}";
          };
        };
      };
      formatter = true;
      lsp = {
        # Disable the built-in pyright server so pyrefly is the sole Python LSP.
        pyright.disabled = true;
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
        postgres-language-server = {
          enabled = true;
          command = [
            "postgres-language-server"
            "lsp-proxy"
          ];
          extensions = [
            ".sql"
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
        chrome-devtools = {
          type = "local";
          command = [
            "npx"
            "-y"
            "chrome-devtools-mcp@latest"
            "--autoConnect"
          ];
          enabled = true;
        };
      };
    };
  };
}
