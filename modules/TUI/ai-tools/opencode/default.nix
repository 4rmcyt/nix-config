{
  pkgs,
  lib,
  config,
  ...
}: let
  systemPrompts = import ../system-prompt;

  # OpenCode agent frontmatter: boolean record for tools, deny-based permissions
  mkOpenCodeAgent = {
    description,
    disableTools ? {},
    denyPermissions ? {},
    body,
  }: let
    toolsLines =
      lib.optionalString (disableTools != {})
      (let
        entries = lib.concatStringsSep "\n" (lib.mapAttrsToList (k: v: "  ${k}: ${lib.boolToString v}") disableTools);
      in "tools:\n${entries}\n");
    permLines =
      lib.optionalString (denyPermissions != {})
      (let
        entries = lib.concatStringsSep "\n" (lib.mapAttrsToList (k: v: "  ${k}: ${v}") denyPermissions);
      in "permission:\n${entries}\n");
  in ''
    ---
    description: "${description}"
    ${toolsLines}${permLines}---

    ${body}
  '';
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
      model = "anthropic/claude-sonnet-4-5";
      small_model = "anthropic/claude-haiku-4-5";
    };

    rules = systemPrompts.llm lib config.programs.mcp.servers;

    agents = {
      "nixos-config" = mkOpenCodeAgent {
        description = "NixOS configuration specialist for modules, options, and services";
        body = builtins.readFile ../agents/nixos-config.md;
      };
      "homeserver-admin" = mkOpenCodeAgent {
        description = "Homeserver administration for k3s, monitoring, networking, and security";
        body = builtins.readFile ../agents/homeserver-admin.md;
      };
      "code-reviewer" = mkOpenCodeAgent {
        description = "Read-only code review agent";
        disableTools = {
          write = false;
          edit = false;
        };
        denyPermissions = {edit = "deny";};
        body = builtins.readFile ../agents/code-reviewer.md;
      };
    };

    commands = {
      "commit" = builtins.readFile ../commands/commit.md;
      "create-plan" = builtins.readFile ../commands/create-plan.md;
      "review-code" = builtins.readFile ../commands/review-code.md;
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
