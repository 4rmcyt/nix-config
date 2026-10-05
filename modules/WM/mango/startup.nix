# Upstream autostart_sh still emits `exec-once` (hm-modules.nix:231 @ 31eae11), which the parser rejects.
{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config.wayland.windowManager.mango) systemd;
  # Mirrors upstream's systemdActivation prefix so mango-session.target still starts
  systemdActivation = "${pkgs.dbus}/bin/dbus-update-activation-environment --systemd ${lib.concatStringsSep " " systemd.variables}; ${lib.concatStringsSep " && " systemd.extraCommands}";
in {
  wayland.windowManager.mango.settings.exec_once = "~/.config/mango/autostart.sh";

  xdg.configFile."mango/autostart.sh" = {
    executable = true;
    source = pkgs.writeShellScript "autostart.sh" ''
      ${lib.optionalString systemd.enable systemdActivation}

      wl-paste --type text --watch cliphist store &
      wl-paste --type image --watch cliphist store &

      wl-clip-persist --clipboard regular &

      # Propagates PAM environment (GIO_EXTRA_MODULES, etc.) into D-Bus/systemd user session
      dbus-update-activation-environment --systemd --all

      # Without it bluetoothd can't answer device_confirm_passkey and devices drop immediately
      blueman-applet &

      # v5 is a single native binary, no Quickshell instance-identity problem (unlike legacy-v4)
      noctalia &

      materialgram &
      vesktop --start-minimized &

      # --disable-gpu works around NVIDIA QtWebEngine glyph corruption
      coolercontrol --disable-gpu &
    '';
  };
}
