{
  pkgs,
  inputs,
  ...
}:
{
  # Enable Hyprland
  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.system}.hyprland;
    portalPackage = inputs.hyprland.packages.${pkgs.system}.xdg-desktop-portal-hyprland;
  };

  # XDG portal
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];
    config.common.default = "*";
  };

  # Session variables for NVIDIA compatibility
  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
    NIXOS_OZONE_WL = "1";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    GBM_BACKEND = "nvidia-drm";
    LIBVA_DRIVER_NAME = "nvidia";
    WLR_DRM_DEVICES = "/dev/dri/card1:/dev/dri/card0";
  };

  # Display manager - ONLY ONE INSTANCE
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  # nwg-shell components only
  environment.systemPackages = with pkgs; [
    brightnessctl
    networkmanagerapplet
    kitty
    # Complete nwg-shell suite
    nwg-panel
    nwg-drawer
    nwg-dock-hyprland
    nwg-look
    nwg-displays
    nwg-launchers
    nwg-menu
    nwg-bar
    nwg-wrapper
    # Optional nwg components
    autotiling # automatic tiling for better window management
  ];

  # System fonts only
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
    liberation_ttf
    font-awesome
    nerd-fonts.fira-code
  ];
}