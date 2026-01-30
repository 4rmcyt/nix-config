{
  config,
  lib,
  ...
}: let
  mcpServerNames = builtins.attrNames config.programs.mcp.servers;
  mcpList = lib.concatMapStringsSep "\n" (name: "- ${name}") mcpServerNames;
in {
  programs.claude-code = {
    enableMcpIntegration = true;

    settings = {
      systemPrompt = ''
        You are an expert software engineer working with a Nix-based configuration system.

        Available MCP servers:
        ${mcpList}

        Always follow Nix best practices:
        - Use declarative configurations
        - Prefer functional programming patterns
        - Maintain reproducible builds
      '';
    };
  };
}
