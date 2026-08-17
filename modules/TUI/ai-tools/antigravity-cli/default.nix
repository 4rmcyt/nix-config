{
  pkgs,
  config,
  lib,
  ...
}: let
  systemPrompts = import ../system-prompt;
  mcpConfigJson = pkgs.writeText "mcp_config.json" (builtins.toJSON {
    mcpServers = config.programs.mcp.servers;
  });
  antigravitySettingsJson = pkgs.writeText "antigravity-cli-settings.json" (builtins.toJSON {
    modelProvider = "gemini";
  });
  geminiMd = pkgs.writeText "GEMINI.md" (systemPrompts.gemini lib config.programs.mcp.servers);
in {
  home.packages = [pkgs.antigravity-cli];

  # Copy config files instead of symlinking
  home.activation.antigravityCliConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p "$HOME/.gemini/config"
    mkdir -p "$HOME/.gemini/antigravity-cli"
    cp -f ${mcpConfigJson} "$HOME/.gemini/config/mcp_config.json"
    cp -f ${antigravitySettingsJson} "$HOME/.gemini/antigravity-cli/settings.json"
    cp -f ${geminiMd} "$HOME/.gemini/GEMINI.md"
    chmod 600 "$HOME/.gemini/config/mcp_config.json"
    chmod 600 "$HOME/.gemini/antigravity-cli/settings.json"
    chmod 600 "$HOME/.gemini/GEMINI.md"
  '';

  programs.zsh.initContent = ''
    if [[ -r /run/secrets/gemini_api_key ]]; then
      export GEMINI_API_KEY="$(cat /run/secrets/gemini_api_key)"
    fi
  '';
}
