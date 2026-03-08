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
    # Patch nfs.mount to use the capability wrapper so gvfsd-nfs can bind privileged ports
    package = pkgs.gvfs.overrideAttrs (old: {
      postInstall =
        (old.postInstall or "")
        + ''
          substituteInPlace $out/share/gvfs/mounts/nfs.mount \
            --replace-fail "${pkgs.gvfs}/libexec/gvfsd-nfs" "/run/wrappers/bin/gvfsd-nfs"
        '';
    });
  };

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
