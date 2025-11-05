_: {
  services.flatpak = {
    enable = true;
    remotes = {
      "flathub" = "https://dl.flathub.org/repo/flathub.flatpakrepo";
      "flathub-beta" = "https://dl.flathub.org/beta-repo/flathub-beta.flatpakrepo";
    };
    packages = [
      "flathub:/root/testflatpak.flatpakref"
      "flathub:app/com.github.iwalton3.jellyfin-media-player//latest"
    ];
  };
}
