{ pkgs, ... }:
{
  wayland.windowManager.hyprland = {
    settings.monitor = [
      "DP-4,3840x2160@59.997,0x0,2.1,bitdepth,10"
      "DP-5,3840x2160@59.997,1829x0,2.1,bitdepth,10"
    ];
    extraConfig = ''
      # hyprlang noerror true
        source = ~/.config/hypr/monitors.conf
        source = ~/.config/hypr/workspaces.conf
      # hyprlang noerror false
    '';
  };

  home.packages = with pkgs; [ nwg-displays ];
}
