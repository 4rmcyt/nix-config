{pkgs, ...}: {
  home.packages = [pkgs.jellyfin-mpv-shim];

  # jellyfin-mpv-shim embeds libmpv and always loads its config from its own
  # config dir (~/.config/jellyfin-mpv-shim/mpv.conf) rather than ~/.config/mpv/,
  # so the HDR/hwdec settings from modules/GUI/mpv are duplicated here.
  xdg.configFile."jellyfin-mpv-shim/mpv.conf".text = ''
    vo=gpu-next
    gpu-context=wayland
    hwdec=nvdec-copy

    # HDR passthrough
    target-colorspace-hint=yes
    target-prim=auto
    target-trc=auto
  '';
}
