# Minimal Home Manager config for the router.
# Headless appliance — no GUI, no desktop tools.
{...}: {
  home.stateVersion = "25.11";

  programs.zsh.enable = true;
}
