_: {
  services.flatpak = {
    enable = true;
    remotes = {
      "flathub" = "https://dl.flathub.org/repo/flathub.flatpakrepo";
      "flathub-beta" = "https://dl.flathub.org/beta-repo/flathub-beta.flatpakrepo";
    };
    packages = [
      "flathub:app/com.github.iwalton3.jellyfin-media-player//stable"
      # Gaming: 32-bit graphics support for Lutris
      "flathub:runtime/org.freedesktop.Platform.GL32.default/x86_64/24.08"
      "flathub:runtime/org.freedesktop.Platform.GL32.nvidia-580-105-08/x86_64/1.4"
      "flathub:runtime/org.freedesktop.Platform.GL32.nvidia-580-105-08/x86_64/1.4"
      "flathub:runtime/org.gnome.Platform.Compat.i386/x86_64/46"
      # Gaming tools for Lutris
      "flathub:runtime/org.freedesktop.Platform.VulkanLayer.gamescope/x86_64/24.08"
      "flathub:runtime/org.freedesktop.Platform.VulkanLayer.MangoHud/x86_64/24.08"
    ];

    # Note: Flatpak overrides for Lutris are applied via flatpak override commands:
    # flatpak override --user net.lutris.Lutris --filesystem=/run/current-system/sw/bin:ro
    # flatpak override --user net.lutris.Lutris --filesystem=~/.steam:ro --filesystem=~/.local/share/Steam:ro --filesystem=xdg-data/Steam:ro
  };
}
