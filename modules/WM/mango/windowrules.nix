# windowrule=Param:Values,Param:Values,appid:Regex,title:Regex
# See https://mangowm.github.io/docs/window-management/rules
_: {
  wayland.windowManager.mango.settings.windowrule = [
    "isfloating:1,title:^(Open File|Save File|File Upload|Confirm to replace files|File Operation Progress)$"

    "isfloating:1,appid:^(org\\.gnome\\.Calculator|org\\.gnome\\.FileRoller)$"

    "isfloating:1,appid:^(org\\.pulseaudio\\.pavucontrol|zenity)$"

    "isfloating:1,appid:^(Viewnior|loupe|org\\.gnome\\.Loupe)$"

    "isfloating:1,appid:^(mpv)$"
    "isfloating:1,title:^(Picture-in-Picture)$"

    "isfloating:1,appid:^(\\.sameboy-wrapped)$"

    "isfloating:1,appid:^(walker)$"

    "isfloating:1,title:^(Volume Control)$"
    "isfloating:1,title:^(Transmission)$"
  ];
}
