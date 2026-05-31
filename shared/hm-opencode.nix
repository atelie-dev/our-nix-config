{ lib, pkgs, ... }:

{
  programs.opencode = {
    enable = true;
    context = ''
      # General rules

      Never interact directly with Git. Orient and ask the user to perform commits or any other git operation.

      When writing or suggesting new code, evaluate the effort using the skill `evaluate-new-dep`.
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
      model = "ollama-cloud/deepseek-v4-flash";
      provider = {
        ollama = {
          name = "Ollama";
          npm = "@ai-sdk/openai-compatible";
          options = {
            baseURL = "http://127.0.0.1:11434/v1";
          };
        };
      };
      lsp = true;
      mcp = {
        atlassian = {
          type = "remote";
          url = "https://mcp.atlassian.com/v1/mcp/authv2";
          enabled = false;
        };
      };
    };
  };
}
