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

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "Hyprland";
        user = "greeter";
      };
    };
  };

  # Essential packages for Hyprland
  environment.systemPackages = with pkgs; [
    waybar
    wofi
    swww
    grim
    slurp
    wl-clipboard
    mako
    brightnessctl
    playerctl
    kitty
    pavucontrol
    networkmanagerapplet
  ];

  # Fonts
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    font-awesome
    nerdfonts
  ];
}
