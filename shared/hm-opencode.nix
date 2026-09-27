{
  lib,
  pkgs,
  config,
  ...
}:
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
    # Built by upstream's own flake (anomalyco/opencode, dev branch) and
    # exposed through the shared overlay in cli-tools.nix; replaces the old
    # nixpkgs package + bun 1.3.13 pin.
    package = pkgs.opencode-flake;
    extraPackages = [
      pkgs.nodejs_24
      # AST-aware code search/replace CLI, used directly via bash by agents
      # (structural refactors that plain grep cannot express).
      pkgs.ast-grep
      # Shellcheck — agents can run it via bash. (The bash-language-server
      # that used to sit here is gone: OpenCode 2 no longer runs LSPs.)
      pkgs.shellcheck
    ];
    context = ''
      # General rules

      Never interact directly with Git. Orient and ask the user to perform commits or any other git operation.

      When writing or suggesting new code, evaluate the effort using the skill `evaluate-new-dep`.

      ## File editing

      * Prefer the built-in `edit` tool (exact `oldString`/`newString` replacement) for modifying existing files; use `write` only for new files or full rewrites.
      * Use `sed`/`awk` only when the same replacement must be applied to several files, or to many occurrences of one pattern at once — never for single, surgical edits.
      * Never create, truncate, or delete files with shell redirection (`>`, `>>`, `tee`), `rm`, or inline `python` scripts. A failed shell edit can destroy a file; the `edit`/`write` tools cannot.

      ## Tool surfaces (critical)

      * **Direct function tools** — `read`, `write`, `edit`, `glob`, `grep`, `shell` — are standalone tool calls. They are NOT inside `execute` and will NEVER appear in the Code Mode catalog. `edit` takes `oldString`/`newString`.
      * **Code Mode (`execute` → `tools.*`)** is for MCP/plugin tools only (namespaces like `image_*`, `nixos`, `firecrawl`, `chrome-devtools`). A tool's absence from catalog `search(...)` proves nothing — call core tools directly.
      * Never re-implement edit/read/search via shell scripts (`sed`, `awk`, `python`) when the direct tool exists. If a direct call errors, report it — don't silently switch to a script workaround.

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
      # V2: `plugin` became `plugins`. All plugins are local V2 ports in
      # plugins/ (auto-discovered) except the fallback engine, which gets
      # its per-agent fallback chains via plugin options. The two V1
      # third-party plugins are gone: direnv was ported to
      # plugins/direnv.ts, and hashline was removed (no V2 release;
      # upstream AngDrew/opencode-hashline last touched April 2026).
      plugins = [
        {
          package = "./plugins/disable-provider-fallback.ts";
          options.fallback = {
            build = [
              "opencode-go/deepseek-v4.1-flash"
              "deepseek/deepseek-v4.1-flash"
              "openrouter/deepseek/deepseek-v4.1-flash"
            ];
            plan = [
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
            explore = [
              "neuralwatt/glm-5.3-flash"
              "opencode-go/glm-5.3-flash"
              "zai-coding-plan/glm-5.3-flash"
              "deepseek/deepseek-v4.1-flash"
              "openrouter/nvidia/nemotron-3-super-120b-a12b:free"
            ];
          };
        }
      ];
      # Primary: Neuralwatt (self-hosted energy pricing). Foreground agents
      # run standard tier; subagents run flex tier (0.65x energy, deferrable).
      # OpenCode Go / Z.AI / Ollama demoted to fallbacks.
      model = "neuralwatt/glm-5.3-flash";
      # V2: `agent` became `agents`; `prompt` -> `system`, `disable` ->
      # `disabled`, model variants join as `model#variant`, grouped
      # `permission` became the ordered `permissions` array.
      agents = {
        build = {
          model = "neuralwatt/deepseek-v4.1-flash#high";
          # The V1 `options.fallback` lists are dropped: OpenCode 2.0.18 has
          # no fallback field in its config schema. They were:
          # opencode-go/deepseek-v4.1-flash, deepseek/deepseek-v4.1-flash,
          # openrouter/deepseek/deepseek-v4.1-flash
        };
        plan = {
          # Interactive agent: full-speed Neuralwatt GLM-5.3 (standard tier,
          # not Flex) so planning never waits on deferrable scheduling.
          # Z.ai Coding Plan is the overflow layer (already paid, yearly).
          model = "neuralwatt/glm-5.3";
          # V1 fallback list (dropped, see build): zai-coding-plan/glm-5.3,
          # opencode-go/glm-5.3, ollama-cloud/glm-5.3,
          # neuralwatt/glm-5.3-flash, opencode-go/glm-5.3-flash,
          # zai-coding-plan/glm-5.3-flash, ollama-cloud/glm-5.3-flash,
          # openrouter/deepseek/deepseek-v4.1-flash,
          # deepseek/deepseek-v4.1-flash
        };
        explore = {
          # Subagent: flex tier (deferrable, 0.65x energy).
          model = "neuralwatt/glm-5.3-flash-flex";
          # V1 {edit, write} = deny collapses to the V2 `edit` action
          # (write/patch merged into edit).
          permissions = [
            {
              action = "edit";
              resource = "*";
              effect = "deny";
            }
          ];
          system = ''
            You are a codebase exploration agent. Your task is to analyze the code structure.
            When searching for patterns, function definitions, or class usages, use the `ast-grep` CLI
            via bash (e.g. `ast-grep run -p 'pattern' --json`) to find them based on syntax trees,
            not just text. This will give more accurate results.
            Do not make any edits.
          '';
          # V1 fallback list (dropped, see build): neuralwatt/glm-5.3-flash,
          # opencode-go/glm-5.3-flash, zai-coding-plan/glm-5.3-flash,
          # deepseek/deepseek-v4.1-flash,
          # openrouter/nvidia/nemotron-3-super-120b-a12b:free
        };
      };
      # V2: `provider` became `providers`; `npm` -> `package` (AI SDK
      # packages take the `aisdk:` prefix); `options.baseURL` ->
      # `settings.baseURL`; `options.apiKey` -> `settings.apiKey`.
      providers = {
        ollama = {
          name = "Ollama";
          package = "aisdk:@ai-sdk/openai-compatible";
          settings.baseURL = "http://127.0.0.1:11434/v1";
        };
        # Z.ai Coding Plan — uses the dedicated /coding/paas/v4 endpoint,
        # which is billed against the Coding Plan subscription quota rather
        # than the general pay-as-you-go API balance. The provider ID
        # `zai-coding-plan` matches the models.dev catalog, which auto-
        # discovers all available models (glm-4.7, glm-5-turbo, glm-5.2,
        # glm-5.2-highspeed, glm-5.3, glm-5.3-highspeed, glm-5.3-flash).
        # Only the API key needs to be supplied.
        zai-coding-plan = {
          settings.apiKey = "{file:${config.home.homeDirectory}/.config/sops-nix/secrets/zai_api_key}";
        };
      };
      formatter = true;
      # NOTE: V2 accepts and preserves `lsp` configuration but does not run
      # language servers, expose LSP tools, or surface diagnostics
      # (https://opencode.ai/v2/docs/migrate-v1). pyrefly and the postgres
      # LSP below are therefore inert until these workflows move to
      # lint/typecheck commands.
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
      # V2 groups servers under `mcp.servers` and inverts `enabled` into
      # `disabled`; the V1 `oauth` toggle is not a V2 field.
      mcp = {
        # 1Password Environments MCP server. Uses the setgid wrapper from
        # shared/onepassword.nix (the app's peer check requires
        # egid=onepassword-mcp). Requires the 1Password app running and
        # unlocked.
        servers = {
          "1password" = {
            type = "local";
            command = [ "/run/wrappers/bin/1password-mcp" ];
          };
          atlassian = {
            type = "remote";
            url = "https://mcp.atlassian.com/v1/mcp/authv2";
            disabled = true;
          };
          nixos = {
            type = "local";
            command = [ "mcp-nixos" ];
          };
          firebase-mcp-server = {
            type = "local";
            command = [
              "firebase"
              "mcp"
            ];
            disabled = true;
          };
          firecrawl = {
            type = "remote";
            url = "https://mcp.firecrawl.dev/v2/mcp";
            headers = {
              Authorization = "Bearer {file:${config.home.homeDirectory}/.config/sops-nix/secrets/firecrawl_api_key}";
            };
          };
          chrome-devtools = {
            type = "local";
            command = [
              "npx"
              "-y"
              "chrome-devtools-mcp@latest"
              "--autoConnect"
            ];
          };
        };
      };
    };
  };
}
