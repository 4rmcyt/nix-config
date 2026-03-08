{pkgs, ...}: {
  # Open any terminal from nautilus context menu
  programs.nautilus-open-any-terminal = {
    enable = true;
    terminal = "kitty";
  };

  # Quick file preview with Space
  services.gnome.sushi.enable = true;

  # Virtual filesystem (NFS, MTP, trash, etc.)
  services.gvfs.enable = true;

  environment.systemPackages = with pkgs; [
    nautilus
    gnome-autoar # archive support
  ];

  # "New Document" context menu: requires a Templates dir with at least one file
  systemd.tmpfiles.rules = [
    "d /home/zeev/Templates 755 zeev users -"
    "f /home/zeev/Templates/New\\ Document.txt 644 zeev users -"
  ];

  # Permanent delete (bypass trash) + other nautilus tweaks via dconf
  programs.dconf.profiles.user.databases = [
    {
      settings = {
        "org/gnome/nautilus/preferences" = {
          show-delete-permanently = true;
          show-create-link = true;
        };
      };
    }
  ];
}
