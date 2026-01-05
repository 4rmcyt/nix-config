_: {
  services.flatpak = {
    enable = true;
    remotes = {
      "flathub" = "https://dl.flathub.org/repo/flathub.flatpakrepo";
    };
    packages = [
      # Hyprland Settings GUI - https://gb.com/mylinuxforwork/hyprland-settings
      "flathub:app/io.github.linuxforwork.HyprlandSettings//stable"
    ];
  };
}
