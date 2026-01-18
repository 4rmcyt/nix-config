_: {
  services.flatpak = {
    enable = true;
    remotes = {
      "flathub" = "https://dl.flathub.org/repo/flathub.flatpakrepo";
    };
    packages = [
      # Hyprland Settings GUI - removed, no longer available on Flathub
      # "flathub:app/io.github.linuxforwork.HyprlandSettings//stable"
    ];
  };
}
