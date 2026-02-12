{config, ...}: {
  programs.zed-editor.userSettings.context_servers = config.programs.mcp.servers;
}
