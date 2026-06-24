{
  pkgs,
  config,
  ...
}: {
  imports = [
    ./extensions.nix
    ./ai.nix
    ./settings.nix
    ./languages.nix
  ];

  programs.zed-editor = {
    enable = true;
    package = pkgs.zed-editor-fhs;
    installRemoteServer = true;
    userSettings.context_servers = config.programs.mcp.servers;
  };
}
