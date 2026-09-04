# windowrule=Param:Values,Param:Values,appid:Regex,title:Regex
# See https://mangowm.github.io/docs/window-management/rules
_: {
  wayland.windowManager.mango.settings.windowrule = [
    # DIALOG WINDOWS
    "isfloating:1,title:^(Open File|Save File|File Upload|Confirm to replace files|File Operation Progress)$"

    # GNOME UTILITIES
    "isfloating:1,appid:^(org\\.gnome\\.Calculator|org\\.gnome\\.FileRoller)$"

    # SYSTEM UTILITIES
    "isfloating:1,appid:^(org\\.pulseaudio\\.pavucontrol|zenity)$"

    # IMAGE VIEWERS
    "isfloating:1,appid:^(Viewnior|loupe|org\\.gnome\\.Loupe)$"

    # MEDIA
    "isfloating:1,appid:^(mpv)$"
    "isfloating:1,title:^(Picture-in-Picture)$"

    # GAMING
    "isfloating:1,appid:^(\\.sameboy-wrapped)$"

    # LAUNCHERS
    "isfloating:1,appid:^(walker)$"

    # VOLUME CONTROL / TRANSMISSION
    "isfloating:1,title:^(Volume Control)$"
    "isfloating:1,title:^(Transmission)$"
  ];
}
