{pkgs, ...}: {
  # gvfs for trash, MTP, SFTP etc. NFS is handled via fstab automount (nfs-client module).
  services.gvfs.enable = true;
  services.udisks2.enable = true;

  # Required for programs.dconf.profiles below (and any other dconf.settings
  # elsewhere in the config, e.g. Home Manager's gtk.nix) to actually take
  # effect — defaults to false, which silently no-ops all dconf writes.
  programs.dconf.enable = true;

  programs.dconf.profiles.user.databases = [
    {
      settings."org/nemo/preferences" = {
        enable-delete = true;
      };
      settings."org/cinnamon/desktop/default-applications/terminal" = {
        exec = "kitty";
      };
      settings."org/gnome/desktop/search-providers" = {
        disable-external = true;
      };
    }
  ];

  environment.systemPackages = with pkgs; [
    nemo-with-extensions
    gnome-autoar
    libheif
    libheif.out
    localsearch
  ];

  environment.pathsToLink = ["/share/thumbnailers"];
}
