{pkgs, ...}: let
  kdeconnectShare = pkgs.writeShellApplication {
    name = "kdeconnect-nemo-share";
    runtimeInputs = with pkgs; [kdePackages.kdeconnect-kde libnotify];
    text = ''
      mapfile -t devices < <(kdeconnect-cli -a --id-name-only)

      if [ "''${#devices[@]}" -eq 0 ]; then
        notify-send -i kdeconnect "KDE Connect" "No reachable devices to share with"
        exit 1
      fi

      for file in "$@"; do
        for entry in "''${devices[@]}"; do
          id="''${entry%% *}"
          name="''${entry#* }"
          kdeconnect-cli --share "$file" --device "$id"
          notify-send -i kdeconnect "KDE Connect" "Sent $(basename "$file") to $name"
        done
      done
    '';
  };
in {
  home.packages = [kdeconnectShare];

  # GTK bookmarks sidebar entry — nfs-client module auto-mounts homeserver:/data at /mnt/media
  xdg.configFile."gtk-3.0/bookmarks".text = ''
    file:///mnt/media Homeserver
  '';

  # Right-click "Send via KDE Connect" — shares to every reachable paired
  # device (kdeconnect-cli has no "pick a device" prompt of its own).
  xdg.dataFile."nemo/actions/kdeconnect-share.nemo_action".text = ''
    [Nemo Action]
    Active=true
    Name=Send via KDE Connect
    Comment=Share the selected file(s) with paired KDE Connect devices
    Exec=kdeconnect-nemo-share %F
    Icon-Name=kdeconnect
    Selection=notnone
    Extensions=nodirs;
    Quote=double
  '';
}
