{
  config,
  lib,
  pkgs,
  ...
}: let
  mkSystemPrompt = import ../../shared/ai-system-prompt.nix;
  mcpConfigJson = pkgs.writeText "mcp-config.json" (builtins.toJSON {
    mcpServers = config.programs.mcp.servers;
  });
in {
  programs.claude-code = {
    enable = true;
    package = pkgs.claude-code;

    settings = {
      systemPrompt = mkSystemPrompt lib config.programs.mcp.servers;
    };
  };

  # Copy MCP config instead of symlinking (Claude has bug with symlinks)
  home.activation.claudeMcpConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p "$HOME/.claude"
    cp -f ${mcpConfigJson} "$HOME/.claude/mcp.json"
    chmod 600 "$HOME/.claude/mcp.json"
  '';
}
