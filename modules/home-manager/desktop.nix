{
  lib,
  osConfig,
  ...
}:
with lib; {
  # =================================================================
  # Automatic Window Manager Module Loading
  # =================================================================
  # This module automatically imports the correct WM configuration
  # based on the system's my.desktop.windowManager setting

  imports =
    let
      wm = osConfig.my.desktop.windowManager or "none";
      wmModules = {
        hyprland = ../WM/hyprland;
        niri = ../WM/niri;
      };
    in
      [../GUI/zed]
      ++ optional (wm != "none" && hasAttr wm wmModules) wmModules.${wm};
}
