{lib, ...}: let
  inherit (lib.generators) mkLuaInline;

  commands = [
    # Clipboard history daemon
    "bash -c 'wl-paste --type text --watch cliphist store'"
    "bash -c 'wl-paste --type image --watch cliphist store'"

    # Clipboard persistence
    "wl-clip-persist --clipboard regular"

    # Propagate PAM environment (GIO_EXTRA_MODULES, etc.) into D-Bus/systemd user session
    # Required for gvfs backends (trash, NFS) to work in Nemo outside GNOME/Cinnamon
    "dbus-update-activation-environment --systemd --all"

    # Desktop shell (systemd startup is deprecated upstream — spawn directly)
    "noctalia-shell"

    # Messaging apps
    "materialgram"
    "vesktop --start-minimized"

    # Fan/pump curve control (nct6687 SuperIO + AMD GPU/liquidctl).
    # No CLI flag for minimize-to-tray exists (unlike corectrl) — enable
    # "Start in Tray" / "Close to Tray" once in the app's own Settings.
    "coolercontrol"
  ];

  execCalls = builtins.concatStringsSep "\n" (map (c: "  hl.exec_cmd(${builtins.toJSON c})") commands);
in {
  wayland.windowManager.hyprland.settings.on = {
    _args = [
      "hyprland.start"
      (mkLuaInline ''
        function()
        ${execCalls}
        end
      '')
    ];
  };
}
