
  };

  # Only system-level essential packages
  environment.systemPackages = with pkgs; [
    brightnessctl
    networkmanagerapplet
    waybar
    wofi
    kitty
  ];

  # System fonts only
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
    liberation_ttf
    font-awesome
    (nerdfonts.override { fonts = [ "FiraCode" ]; })
  ];
}