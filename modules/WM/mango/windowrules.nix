# window_rule=Param:Values,Param:Values,app_id:Regex,title:Regex
# See https://mangowm.github.io/docs/window-management/rules
_: {
  wayland.windowManager.mango.settings.window_rule = [
    "is_floating:1,title:^(Open File|Save File|File Upload|Confirm to replace files|File Operation Progress)$"

    "is_floating:1,app_id:^(org\\.gnome\\.Calculator|org\\.gnome\\.FileRoller)$"

    "is_floating:1,app_id:^(org\\.pulseaudio\\.pavucontrol|zenity)$"

    "is_floating:1,app_id:^(Viewnior|loupe|org\\.gnome\\.Loupe)$"

    "is_floating:1,app_id:^(mpv)$"
    "is_floating:1,title:^(Picture-in-Picture)$"

    "is_floating:1,app_id:^(\\.sameboy-wrapped)$"

    "is_floating:1,app_id:^(walker)$"

    "is_floating:1,title:^(Volume Control)$"
    "is_floating:1,title:^(Transmission)$"
  ];
}
