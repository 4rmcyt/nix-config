{
  pkgs,
  config,
  lib,
  ...
}: let
  systemPrompts = import ../system-prompt;
  geminiSettingsJson = pkgs.writeText "gemini-settings.json" (builtins.toJSON {
    mcpServers = config.programs.mcp.servers;
    security.auth.selectedType = "gemini-api-key";
    general.previewFeatures = true;
  });
  geminiMd = pkgs.writeText "GEMINI.md" (systemPrompts.gemini lib config.programs.mcp.servers);
in {
  home.packages = [pkgs.gemini-cli];

  # Copy config files instead of symlinking
  home.activation.geminiConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p "$HOME/.gemini"
    cp -f ${geminiSettingsJson} "$HOME/.gemini/settings.json"
    cp -f ${geminiMd} "$HOME/.gemini/GEMINI.md"
    chmod 600 "$HOME/.gemini/settings.json"
    chmod 600 "$HOME/.gemini/GEMINI.md"
  '';

  programs.zsh.initContent = ''
    if [[ -r /run/secrets/gemini_api_key ]]; then
      export GEMINI_API_KEY="$(cat /run/secrets/gemini_api_key)"
    fi
  '';
}
