{pkgs, ...}: {
  home.packages = [pkgs.material-design-icons];
  programs.mpv = {
    enable = true;
    scripts = with pkgs; [
      mpvScripts.modernx
      mpvScripts.mpris
      mpvScripts.quality-menu
      mpvScripts.sponsorblock
      mpvScripts.thumbfast
    ];
    config = {
      osc = false;
      save-position-on-quit = true;
      keep-open = true;
      sub-fix-timing = true;
      blend-subtitles = true;
      sub-auto = "fuzzy";
      slang = "en,eng,enUS,en-US";
      user-agent = "Mozilla/5.0";
      vo = "gpu-next";
      gpu-context = "wayland";
      hwdec = "nvdec-copy";

      # HDR support
      target-colorspace-hint = true;
      target-prim = "auto";
      target-trc = "auto";
    };
    bindings = {
      "ctrl+f" = "script-binding quality_menu/video_formats_toggle";
      "." = "cycle-values video-aspect \"16:9\" \"4:3\" \"2.35:1\" \"-1\"";
      "s" = "cycle-values sub-pos 100 60";
      "ENTER" = "cycle-values fullscreen yes no";
      "KP_ENTER" = "cycle-values fullscreen yes no";
      "MOUSE_BTN1" = "cycle-values fullscreen yes no";
      "MOUSE_BTN0" = "cycle pause";
      "CTRL+UP" = "add sub-font-size 2";
      "CTRL+DOWN" = "add sub-font-size -2";
      "UP" = "add volume 2";
      "DOWN" = "add volume -2";
      "KP4" = "playlist-prev";
      "KP6" = "playlist-next";
      "<" = "add sub-delay -0.1";
      ">" = "add sub-delay +0.1";
      "*" = "set speed 1";
      "+" = "add speed +0.1";
      "KP_ADD" = "add speed +0.1";
      "-" = "add speed -0.1";
      "KP_SUBTRACT" = "add speed -0.1";
    };
  };
}
