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

  # noctalia-shell's Quickshell.iconPath() (legacy v4, archived upstream —
  # see modules/WM/mango/noctalia.nix) fails to resolve the generic
  # freedesktop icon name "system-file-manager" in the launcher, even
  # though the file exists in every icon theme tried (Tela-dark,
  # Papirus-Dark) and other apps' icons resolve fine. App-specific icon
  # names work where the generic one doesn't, so point Nemo's Icon= at its
  # own name instead. ~/.local/share/applications/ shadows the package's
  # /share/applications/nemo.desktop in XDG desktop-file lookup.
  xdg.dataFile."applications/nemo.desktop".source = pkgs.runCommand "nemo-desktop-icon-fix" {} ''
    sed 's/^Icon=system-file-manager$/Icon=nemo/' ${pkgs.nemo-with-extensions}/share/applications/nemo.desktop > $out
  '';

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
