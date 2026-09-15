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
    enable = true;
    package = pkgs.claude-code;
    enableMcpIntegration = true;

    context = systemPrompts.claude lib config.programs.mcp.servers;

    settings = {
      alwaysThinkingEnabled = false;
      effortLevel = "medium";
      hooks = {
        PreToolUse = [
          {
            matcher = "Bash";
            hooks = [
              {
                type = "command";
                command = ''
                  c=$(jq -r '.tool_input.command // empty')
                  if { [ -n "$SSH_CONNECTION" ] && echo "$c" | grep -qE '(^|[;&|][[:space:]]*)sudo\b'; } || { echo "$c" | grep -qE '\bssh\b' && echo "$c" | grep -qE '\bsudo\b'; }; then
                    echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"sudo over SSH is forbidden - run it on the remote host yourself."}}'
                  fi
                '';
              }
              {
                type = "command";
                command = ''
                  c=$(jq -r '.tool_input.command // empty')
                  if echo "$c" | grep -qE '\bnixos-rebuild\b|\bnh[[:space:]]+os\b|\bnix[[:space:]]+build\b|\bnix[[:space:]]+flake[[:space:]]+check\b'; then
                    echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Build, rebuild and flake check are not run from here - state the change and stop."}}'
                  fi
                '';
              }
              {
                type = "command";
                command = ''
                  c=$(jq -r '.tool_input.command // empty')
                  if echo "$c" | grep -qE '\bsops[[:space:]]+(-e\b|--encrypt\b|encrypt\b)'; then
                    echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Never run sops encrypt from a tool call - give the user the command instead."}}'
                  fi
                '';
              }
            ];
          }
        ];
        PostToolUseFailure = [
          {
            matcher = "Bash";
            hooks = [
              {
                type = "command";
                command = ''
                  if grep -qi "permission denied"; then
                    echo '{"hookSpecificOutput":{"hookEventName":"PostToolUseFailure","additionalContext":"Permission denied - stop and ask the user how to proceed instead of retrying alternate commands."}}'
                  fi
                '';
              }
            ];
          }
        ];
      };
    };

    agents = {
      "nixos-config" = mkClaudeAgent {
        description = "NixOS configuration specialist for modules, options, and services";
        tools = ["Read" "Write" "Edit" "Glob" "Grep" "Bash" "mcp__mcp-nixos" "mcp__filesystem" "mcp__github" "mcp__sequential-thinking"];
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
