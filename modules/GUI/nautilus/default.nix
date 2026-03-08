{
  lib,
  pkgs,
  config,
  ...
}: let
  gvfsPkg = pkgs.gvfs.overrideAttrs (_old: {
    postInstall = ''
      ln -sf /run/wrappers/bin/gvfsd-nfs $out/libexec/gvfsd-nfs
    '';
  });
in {
  programs.nautilus-open-any-terminal = {
    enable = true;
    terminal = "kitty";
  };

  # Give gvfsd-nfs cap_net_bind_service so it can connect to NFS servers
  # that don't have the `insecure` export flag (gvfsd-nfs uses unprivileged ports).
  security.wrappers.gvfsd-nfs = {
    source = "${gvfsPkg}/libexec/gvfsd-nfs";
    owner = "nobody";
    group = "nogroup";
    capabilities = "cap_net_bind_service+ep";
  };

  services.gvfs = {
    enable = true;
    package = lib.mkForce gvfsPkg;
  };

  services.gnome.sushi.enable = true;

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
