{
  config,
  lib,
  pkgs,
  ...
}: let
  systemPrompts = import ../system-prompt;

  # Claude Code agent frontmatter: YAML array of tool names
  mkClaudeAgent = {
    description,
    tools,
    body,
  }: let
    toolsList = lib.concatMapStringsSep "\n" (t: "  - ${t}") tools;
  in ''
    ---
    description: ${description}
    tools:
    ${toolsList}
    ---

    ${body}
  '';
in {
  programs.claude-code = {
    enable = lib.mkForce false; # 2.1.88 removed from npm, re-enable after nixpkgs updates
    package = pkgs.claude-code;
    enableMcpIntegration = true;

    memory.text = systemPrompts.claude lib config.programs.mcp.servers;

    settings = {
      hooks = {
        SessionStart = [
          {
            matcher = "";
            hooks = [
              {
                type = "command";
                command = "${lib.getExe pkgs.beads} prime";
              }
            ];
          }
        ];
        PreCompact = [
          {
            matcher = "";
            hooks = [
              {
                type = "command";
                command = "${lib.getExe pkgs.beads} prime";
              }
            ];
          }
        ];
      };
    };

    agents = {
      "nixos-config" = mkClaudeAgent {
        description = "NixOS configuration specialist for modules, options, and services";
        tools = ["Read" "Write" "Edit" "Glob" "Grep" "Bash" "mcp__mcp-nixos" "mcp__filesystem" "mcp__grep-mcp" "mcp__sequential-thinking"];
        body = builtins.readFile ../agents/nixos-config.md;
      };
      "homeserver-admin" = mkClaudeAgent {
        description = "Homeserver administration for k3s, monitoring, networking, and security";
        tools = ["Read" "Write" "Edit" "Glob" "Grep" "Bash" "mcp__kubernetes" "mcp__mcp-nixos" "mcp__filesystem" "mcp__sequential-thinking"];
        body = builtins.readFile ../agents/homeserver-admin.md;
      };
      "code-reviewer" = mkClaudeAgent {
        description = "Read-only code review agent";
        tools = ["Read" "Glob" "Grep" "Bash" "mcp__mcp-nixos"];
        body = builtins.readFile ../agents/code-reviewer.md;
      };
    };

    commands = {
      "commit" = builtins.readFile ../commands/commit.md;
      "create-plan" = builtins.readFile ../commands/create-plan.md;
      "review-code" = builtins.readFile ../commands/review-code.md;
    };

    skills = {
      "nixos-advisor" = builtins.readFile ../skills/nixos-advisor/SKILL.md;
      "nixos-command-not-found" = builtins.readFile ../skills/nixos-command-not-found/SKILL.md;
    };
  };
}
