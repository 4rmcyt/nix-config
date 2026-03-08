{pkgs, ...}: let
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
      settings."org/gnome/desktop/search-providers" = {
        disable-external = true;
      };
    }
  ];

  environment.systemPackages = with pkgs; [
    nautilusPkg
    gnome-autoar
    libheif
    libheif.out
    localsearch
    code-nautilus
  ];

  environment.pathsToLink = ["/share/thumbnailers"];
}
