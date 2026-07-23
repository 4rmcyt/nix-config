_: {
  # GTK bookmarks sidebar entry — nfs-client module auto-mounts homeserver:/data at /mnt/media
  xdg.configFile."gtk-3.0/bookmarks".text = ''
    file:///mnt/media Homeserver
  '';
}
