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
  systemd.user.services.gvfs-daemon = {
    description = "GVfs daemon";
    wantedBy = ["graphical-session.target"];
    partOf = ["graphical-session.target"];
    serviceConfig = {
      ExecStart = "${pkgs.gvfs}/libexec/gvfsd";
      Restart = "on-failure";
    };
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
