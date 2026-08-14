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
          ];
        };
        plan = {
          model = "ollama-cloud/glm-5.2";
          options.fallback = [
            "ollama-cloud-2/glm-5.2"
            "ollama-cloud/deepseek-v4-flash"
            "ollama-cloud-2/deepseek-v4-flash"
            "deepseek/deepseek-v4-flash"
            "openrouter/nvidia/nemotron-3-super-120b-a12b:free"
            "openrouter/poolside/laguna-s-2.1:free"
          ];
        };
        explore = {
          mode = "subagent";
          options.fallback = [
            "ollama-cloud-2/deepseek-v4-flash"
            "deepseek/deepseek-v4-flash"
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
        # `models` must be declared explicitly: `ollama-cloud-2` is a custom
        # provider id that models.dev does not know, so the /model picker
        # stays empty without this block. Metadata mirrors the models.dev
        # catalog for the built-in `ollama-cloud` provider.
        ollama-cloud-2 = {
          name = "Ollama Cloud 2";
          npm = "@ai-sdk/openai-compatible";
          options = {
            baseURL = "https://ollama.com/v1";
            apiKey = "{file:${config.home.homeDirectory}/.config/sops-nix/secrets/ollama_cloud_api_key}";
          };
          models = {
            "deepseek-v4-flash" = {
              name = "DeepSeek V4 Flash 0731";
              family = "deepseek-flash";
              attachment = false;
              reasoning = true;
              tool_call = true;
              temperature = true;
              limit = {
                context = 1048576;
                output = 1048576;
              };
            };
            "glm-5.2" = {
              name = "GLM-5.2";
              family = "glm";
              attachment = false;
              reasoning = true;
              tool_call = true;
              interleaved = {
                field = "reasoning_content";
              };
              temperature = true;
              limit = {
                context = 976000;
                output = 131072;
              };
            };
            "gemma4:31b" = {
              name = "Gemma 4 31B Cloud";
              family = "gemma";
              attachment = true;
              reasoning = true;
              tool_call = true;
              temperature = true;
              limit = {
                context = 262144;
                output = 131072;
              };
            };
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
