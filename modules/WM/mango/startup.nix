# wayland.windowManager.mango.autostart_sh is written to
# ~/.config/mango/autostart.sh with an exec-once line auto-added.
# See https://mangowm.github.io/docs/nix-options#autostart_sh
_: {
  wayland.windowManager.mango.autostart_sh = ''
    # Clipboard history daemon
    wl-paste --type text --watch cliphist store &
    wl-paste --type image --watch cliphist store &

    # Clipboard persistence
    wl-clip-persist --clipboard regular &

    # Propagate PAM environment (GIO_EXTRA_MODULES, etc.) into D-Bus/systemd user session
    dbus-update-activation-environment --systemd --all

    # Bluetooth pairing agent — without it bluetoothd has nothing to answer
    # device_confirm_passkey requests, so devices (e.g. Bluetooth
    # controllers) connect and are immediately dropped.
    blueman-applet &

    # Desktop shell — v5 is a single native binary with no Quickshell
    # instance-identity problem to work around (unlike legacy-v4).
    noctalia &

    # Messaging apps
    materialgram &
    vesktop --start-minimized &

    # Fan/pump curve control — see modules/WM/hyprland/startup.nix for the
    # --disable-gpu rationale (NVIDIA QtWebEngine glyph corruption workaround)
    coolercontrol --disable-gpu &
  '';
}
