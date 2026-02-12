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

    rules = systemPrompts.llm lib config.programs.mcp.servers;

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
  };
}
