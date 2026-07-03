# Minimal Home Manager config for the router.
# Headless appliance — no GUI, no desktop tools.
{
  config,
  pkgs,
  ...
}: {
  home.stateVersion = "25.11";

  programs.zsh.enable = true;

  programs.git = {
    enable = true;
    userName = config.my.defaults.gitUsername;
    userEmail = config.my.defaults.email;
  };

  home.packages = with pkgs; [
    curl
    htop
    jq
  ];
}
