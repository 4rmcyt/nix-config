{
  config,
  lib,
  pkgs,
  ...
}: let
  systemPrompts = import ../system-prompt;
in {
  programs.claude-code = {
    enable = true;
    package = pkgs.claude-code;
    enableMcpIntegration = true;

    memory.text = systemPrompts.claude lib config.programs.mcp.servers;

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

    agents = {
      "nixos-config" = builtins.readFile ../agents/nixos-config.md;
      "homeserver-admin" = builtins.readFile ../agents/homeserver-admin.md;
      "code-reviewer" = builtins.readFile ../agents/code-reviewer.md;
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
