{pkgs, ...}: let
  # jellyfin_mpv_shim/default_shader_pack isn't in the repo — gen_pkg.sh
  # fetches it from the latest iwalton3/default-shader-pack release at build
  # time. Without it VideoProfileManager raises FileNotFoundError at startup.
  defaultShaderPack = pkgs.fetchFromGitHub {
    owner = "iwalton3";
    repo = "default-shader-pack";
    rev = "v3.0.0";
    hash = "sha256-lHFidCHBduvNBy1HGgqLDqZMJeLv3jfVWQ73Hlev7w8=";
  };

  # Tracks the head of the mpv-based UI rewrite branch (pre-release 9 and
  # beyond), not yet on a stable PyPI release nixpkgs can track.
  # https://github.com/jellyfin/jellyfin-mpv-shim/tree/local-ui-mpvtk
  jellyfin-mpv-shim-pre9 = pkgs.jellyfin-mpv-shim.overrideAttrs (old: {
    version = "3.0.0pre9-unstable-2026-07-24";
    src = pkgs.fetchFromGitHub {
      owner = "jellyfin";
      repo = "jellyfin-mpv-shim";
      rev = "local-ui-mpvtk";
      hash = "sha256-lnY4L2aMw3fbGmHsEsJnanm7zfKaXGLGjssc06r/CWo=";
    };
    postPatch =
      old.postPatch
      + ''
        cp -r ${defaultShaderPack} jellyfin_mpv_shim/default_shader_pack
        chmod -R u+w jellyfin_mpv_shim/default_shader_pack
      '';
  });
in {
  home.packages = [jellyfin-mpv-shim-pre9];

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
