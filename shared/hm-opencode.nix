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
          options.fallback = [
            "ollama-cloud-2/deepseek-v4-flash"
            "deepseek/deepseek-v4-flash"
            "openrouter/nvidia/nemotron-3-super-120b-a12b:free"
          ];
        };
        plan = {
          model = "ollama-cloud/glm-5.2";
          options.fallback = [
            "ollama-cloud-2/glm-5.2"
            "neuralwatt/glm-5.2"
            "zai-coding-plan/glm-5.2"
            "ollama-cloud/minimax-m3"
            "ollama-cloud-2/minimax-m3"
            "deepseek/deepseek-v4-pro"
          ];
        };
        explore = {
          mode = "subagent";
          options.fallback = [
            "ollama-cloud-2/deepseek-v4-flash"
            "deepseek/deepseek-v4-flash"
            "openrouter/nvidia/nemotron-3-super-120b-a12b:free"
          ];
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
        # Second Ollama Cloud account — API key read from the SOPS-decrypted
        # file at ~/.config/sops-nix/secrets/ollama_cloud_api_key.
        # The primary `ollama-cloud` provider is left as the built-in, which
        # authenticates via ~/.local/share/opencode/auth.json (/connect).
        # Models on this provider are selected as `ollama-cloud-2/<model>`.
        # Model metadata is inherited from the models.dev `ollama-cloud`
        # catalog by the local provider-alias plugin (see
        # ~/.config/opencode/plugins/provider-alias.ts), so no `models`
        # block is needed here.
        ollama-cloud-2 = {
          name = "Ollama Cloud 2";
          npm = "@ai-sdk/openai-compatible";
          options = {
            baseURL = "https://ollama.com/v1";
            apiKey = "{file:${config.home.homeDirectory}/.config/sops-nix/secrets/ollama_cloud_api_key}";
          };
        };
        # Z.ai Coding Plan — uses the dedicated /coding/paas/v4 endpoint,
        # which is billed against the Coding Plan subscription quota rather
        # than the general pay-as-you-go API balance. The provider ID
        # `zai-coding-plan` matches the models.dev catalog, which auto-
        # discovers all available models (glm-4.7, glm-5-turbo, glm-5.2,
        # glm-5.2-highspeed, glm-5.3). Only the API key needs to be supplied.
        zai-coding-plan = {
          options = {
            apiKey = "{file:${config.home.homeDirectory}/.config/sops-nix/secrets/zai_api_key}";
          };
        };
      };
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
