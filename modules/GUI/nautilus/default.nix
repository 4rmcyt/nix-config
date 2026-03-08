{pkgs, config, ...}: let
  nautilusPkg = pkgs.nautilus.overrideAttrs (old: {
    buildInputs =
      old.buildInputs
      ++ (with pkgs.gst_all_1; [
        gst-plugins-good
        gst-plugins-bad
      ]);
  });
in {
  programs.nautilus-open-any-terminal = {
    enable = true;
    terminal = "kitty";
  };

  # gvfs for trash, MTP, SFTP etc. NFS is handled via fstab automount (nfs-client module).
  services.gvfs.enable = true;

  services.gnome.sushi.enable = true;
  services.udisks2.enable = true;

  programs.dconf.profiles.user.databases = [
    {
      settings."org/gnome/nautilus/preferences" = {
        show-delete-permanently = true;
      };
    }
  ];

  environment.systemPackages = with pkgs; [
    nautilusPkg
    gnome-autoar
    libheif
    libheif.out
  ];

  environment.pathsToLink = ["/share/thumbnailers"];

  home-manager.users.${config.my.defaults.user}.xdg.configFile."gtk-3.0/bookmarks".text = ''
    file:///mnt/media Media
  '';
}
