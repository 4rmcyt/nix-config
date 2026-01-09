_: {
  services.flatpak = {
    enable = true;
    remotes = {
      "flathub" = "https://dl.flathub.org/repo/flathub.flatpakrepo";
    };
    packages = [
      # Add niri-specific flatpak applications here if needed
      # Currently niri doesn't have a specific settings GUI flatpak
      # DMS provides all configuration through its native settings
    ];
  };
}
