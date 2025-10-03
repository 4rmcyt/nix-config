{
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    ./extensions.nix
    ./policies.nix
    ./preferences.nix
    ./searchEngines.nix
    ./ui.nix
    inputs.betterfox-nix.homeModules.betterfox
  ];

  ome.sessionVariables = {
    # Improved Wayland support
    MOZ_ENABLE_WAYLAND = 1;
    MOZ_WEBRENDER = 1;
    MOZ_USE_XINPUT2 = 1;
    MOZ_DISABLE_RDD_SANDBOX = 1;
    # Better DMA-BUF support
    MOZ_DRM_DEVICE = "/dev/dri/renderD128";
  };
  
  programs.firefox = {
    enable = true;
    package = inputs.firefox-nightly.packages.x86_64-linux.firefox-nightly-bin;
    nativeMessagingHosts = [ pkgs.browserpass ];
    betterfox = {
      enable = true;
      profiles.default.settings = {
        fastfox.enable = true;
      };
    };
  };
  home.file.".mozilla/firefox/profiles.ini".force = true;
  home.sessionVariables.BROWSER = "firefox";
}
