_: {
  services.flatpak = {
    enable = true;
    remotes = {
      "flathub" = "https://dl.flathub.org/repo/flathub.flatpakrepo";
      "flathub-beta" = "https://dl.flathub.org/beta-repo/flathub-beta.flatpakrepo";
    };
    packages = [
      "flathub:app/org.kde.index//stable"
      "flathub-beta:app/org.kde.kdenlive/x86_64/stable"
      "flathub:/root/testflatpak.flatpakref"
      "flathub:app/com.github.iwalton3.jellyfin-media-player//latest"
    ];
    # overrides = {
    #   "global".Context = {
    #     filesystems = [
    #       "home"
    #     ];
    #     sockets = [
    #       "!x11"
    #       "!fallback-x11"
    #       "wayland"
    #     ];
    #   };
    # };
  };
}
