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
      # Primary: Neuralwatt (self-hosted energy pricing). Foreground agents
      # run standard tier; subagents run flex tier (0.65x energy, deferrable).
      # OpenCode Go / Z.AI / Ollama demoted to fallbacks.
      model = "neuralwatt/glm-5.3-flash";
      agent = {
        build = {
          model = "neuralwatt/deepseek-v4.1-flash";
          variant = "high";
          options.fallback = [
            "opencode-go/deepseek-v4.1-flash"
            "deepseek/deepseek-v4.1-flash"
            "openrouter/deepseek/deepseek-v4.1-flash"
          ];
        };
        plan = {
          # Interactive agent: full-speed Neuralwatt GLM-5.3 (standard tier,
          # not Flex) so planning never waits on deferrable scheduling.
          # Z.ai Coding Plan is the overflow layer (already paid, yearly).
          model = "neuralwatt/glm-5.3";
          options.fallback = [
            "zai-coding-plan/glm-5.3"
            "opencode-go/glm-5.3"
            "ollama-cloud/glm-5.3"
            "neuralwatt/glm-5.3-flash"
            "opencode-go/glm-5.3-flash"
            "zai-coding-plan/glm-5.3-flash"
            "ollama-cloud/glm-5.3-flash"
            "openrouter/deepseek/deepseek-v4.1-flash"
            "deepseek/deepseek-v4.1-flash"
          ];
        };
        explore = {
          # Subagent: flex tier (deferrable, 0.65x energy).
          model = "neuralwatt/glm-5.3-flash-flex";
          options.fallback = [
            "neuralwatt/glm-5.3-flash"
            "opencode-go/glm-5.3-flash"
            "zai-coding-plan/glm-5.3-flash"
            "deepseek/deepseek-v4.1-flash"
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
        # Neuralwatt serves these models but the models.dev catalog lags
        # behind (it still lacks glm-5.3-flash and deepseek-v4.1-flash),
        # so they are declared explicitly here. Rates from
        # portal.neuralwatt.com/pricing (token pricing; energy billing is
        # capped against these rates anyway).
        neuralwatt = {
          models = {
            "glm-5.3-flash" = {
              name = "GLM 5.3 Flash";
              attachment = false;
              reasoning = true;
              tool_call = true;
              temperature = true;
              release_date = "2026-08-26";
              limit = {
                context = 1048560;
                output = 1048560;
              };
              cost = {
                input = 0.15;
                output = 0.5;
                cache_read = 0.03;
              };
            };
            # Flex tier: 0.65x energy discount for deferrable requests.
            # Not yet in models.dev (same PR #7482 gap) — declared here.
            "glm-5.3-flash-flex" = {
              name = "GLM 5.3 Flash (Flex)";
              attachment = false;
              reasoning = true;
              tool_call = true;
              temperature = true;
              release_date = "2026-08-26";
              limit = {
                context = 1048560;
                output = 1048560;
              };
              cost = {
                input = 0.0975;
                output = 0.325;
                cache_read = 0.0195;
              };
            };
            "glm-5.3-flex" = {
              name = "GLM 5.3 (Flex)";
              attachment = false;
              reasoning = true;
              tool_call = true;
              temperature = true;
              release_date = "2026-08-14";
              limit = {
                context = 1048560;
                output = 1048560;
              };
              cost = {
                input = 0.9425;
                output = 2.925;
                cache_read = 0.09425;
              };
            };
            "deepseek-v4.1-flash" = {
              name = "DeepSeek V4.1 Flash";
              attachment = false;
              reasoning = true;
              tool_call = true;
              temperature = true;
              release_date = "2026-08-20";
              limit = {
                context = 1048560;
                output = 393216;
              };
              cost = {
                input = 0.15;
                output = 0.6;
                cache_read = 0.015;
              };
            };
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
        # 1Password Environments MCP server. Uses the setgid wrapper from
        # shared/onepassword.nix (the app's peer check requires
        # egid=onepassword-mcp). Requires the 1Password app running and
        # unlocked.
        "1password" = {
          type = "local";
          command = [ "/run/wrappers/bin/1password-mcp" ];
          enabled = true;
        };
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
