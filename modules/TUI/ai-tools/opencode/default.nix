{
  pkgs,
  lib,
  config,
  ...
}: let
  systemPrompts = import ../system-prompt;
in {
  programs.opencode = {
    enable = true;
    package = pkgs.opencode;
    enableMcpIntegration = true;

    settings = {
      provider = {
        anthropic = {
          options = {
            apiKey = "{env:ANTHROPIC_API_KEY}";
          };
        };
        local = {
          npm = "@ai-sdk/openai-compatible";
          name = "Local";
          options = {
            baseURL = "http://127.0.0.1:8080/v1";
            apiKey = "not-needed";
          };
          models = {
            default = {
              name = "Default";
              limit = {
                context = 8192;
                output = 4096;
              };
            };
          };
        };
      };
      model = "anthropic/claude-sonnet-4-6";
      small_model = "anthropic/claude-haiku-4-5-20251001";
    };

    context = systemPrompts.llm lib config.programs.mcp.servers;

    agents = {
      "nixos-config" = ../agents/nixos-config.md;
      "homeserver-admin" = ../agents/homeserver-admin.md;
      "code-reviewer" = ../agents/code-reviewer.md;
    };

    commands = {
      "commit" = ../commands/commit.md;
      "create-plan" = ../commands/create-plan.md;
      "review-code" = ../commands/review-code.md;
    };

    skills = {
      "nixos-advisor" = ../skills/nixos-advisor;
      "nixos-command-not-found" = ../skills/nixos-command-not-found;
    };
  };

  programs.zsh.initContent = ''
    opencode() {
      if [[ -z "$ANTHROPIC_API_KEY" ]]; then
        ANTHROPIC_API_KEY="$(${pkgs.sops}/bin/sops -d ${../../../../secrets/common.yaml} | ${pkgs.yq}/bin/yq -r '.claude_api_key')" \
          command opencode "$@"
      else
        command opencode "$@"
      fi
    }
  '';
}
