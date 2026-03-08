{
  pkgs,
  config,
  ...
}: {
  programs.nautilus-open-any-terminal = {
    enable = true;
    terminal = "kitty";
  };

  services.gnome.sushi.enable = true;
  services.gvfs = {
    enable = true;
    package = pkgs.gvfs;
  };

  # gvfsd-nfs needs cap_net_bind_service to bind to privileged NFS ports
  security.wrappers.gvfsd-nfs = {
    source = "${pkgs.gvfs}/libexec/gvfsd-nfs";
    capabilities = "cap_net_bind_service=+ep";
    owner = "root";
    group = "root";
  };

  programs.dconf.profiles.user.databases = [
    {
      settings."org/gnome/nautilus/preferences" = {
        show-delete-permanently = true;
      };
    }
  ];

  environment.systemPackages = with pkgs; [
    nautilus
    gnome-autoar
  ];

  home-manager.users.${config.my.defaults.user}.xdg.configFile."gtk-3.0/bookmarks".text = ''
    nfs://homeserver:/data/media Media
  '';
}
