_: {
  services.flatpak = {
    enable = true;
    remotes = {
      "flathub" = "https://dl.flathub.org/repo/flathub.flatpakrepo";
      "flathub-beta" = "https://dl.flathub.org/beta-repo/flathub-beta.flatpakrepo";
    };
    packages = [
      # Hyprland Settings GUI - removed, no longer available on Flathub
      # "flathub:app/io.github.linuxforwork.HyprlandSettings//stable"
    ];
  };
}
