{
  config,
  lib,
  ...
}: {
  imports = [../../shared/ai-system-prompt.nix];

  programs.claude-code = {
    enableMcpIntegration = true;

    settings = {
      systemPrompt = lib.ai.mkSystemPrompt config.programs.mcp.servers;
    };
  };
}
