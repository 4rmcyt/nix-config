{
  config,
  pkgs,
  lib,
  ...
}: let
  mcpConfig = {mcpServers = config.programs.mcp.servers;};
  mkSystemPrompt = import ../../../TUI/ai-tools/system-prompt;
  mcpConfigJson = pkgs.writeText "mcp-config.json" (builtins.toJSON mcpConfig);
  claudeMd = pkgs.writeText "CLAUDE.md" (mkSystemPrompt lib config.programs.mcp.servers);
in {
  home.packages = with pkgs; [
    nodejs
    uv
  ];

  # Copy config files instead of symlinking (Claude/Cline have bugs with symlinks)
  home.activation.claudeDesktopConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p "$HOME/.config/Claude"
    mkdir -p "$HOME/.config/Code/User/globalStorage/saoudrizwan.claude-dev/settings"
    mkdir -p "$HOME/.config/claude"

    cp -f ${mcpConfigJson} "$HOME/.config/Claude/claude_desktop_config.json"
    cp -f ${mcpConfigJson} "$HOME/.config/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json"
    cp -f ${claudeMd} "$HOME/.config/claude/CLAUDE.md"

    chmod 600 "$HOME/.config/Claude/claude_desktop_config.json"
    chmod 600 "$HOME/.config/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json"
    chmod 600 "$HOME/.config/claude/CLAUDE.md"
  '';
}
