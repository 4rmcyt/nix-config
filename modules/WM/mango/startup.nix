# wayland.windowManager.mango.autostart_sh is written to
# ~/.config/mango/autostart.sh with an exec-once line auto-added.
# See https://mangowm.github.io/docs/nix-options#autostart_sh
_: {
  wayland.windowManager.mango.autostart_sh = ''
    wl-paste --type text --watch cliphist store &
    wl-paste --type image --watch cliphist store &

    wl-clip-persist --clipboard regular &

    # Propagates PAM environment (GIO_EXTRA_MODULES, etc.) into D-Bus/systemd user session
    dbus-update-activation-environment --systemd --all

    # Without it, bluetoothd has nothing to answer device_confirm_passkey requests, so
    # devices connect and are immediately dropped.
    blueman-applet &

    # v5 is a single native binary, no Quickshell instance-identity problem (unlike legacy-v4)
    noctalia &

    materialgram &
    vesktop --start-minimized &

    # --disable-gpu works around NVIDIA QtWebEngine glyph corruption
    coolercontrol --disable-gpu &
  '';
}
