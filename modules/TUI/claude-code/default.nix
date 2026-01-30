{
  config,
  lib,
  ...
}: let
  mkSystemPrompt = import ../../shared/ai-system-prompt.nix;
in {
  programs.claude-code = {
    enableMcpIntegration = true;

    settings = {
      systemPrompt = mkSystemPrompt lib config.programs.mcp.servers;
    };
  };
}
