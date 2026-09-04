{
  qt = {
    enable = true;
    platformTheme.name = "qtct";
    style.name = "kvantum";
    qt5ctSettings.Appearance.icon_theme = "Papirus-Dark";
    qt6ctSettings.Appearance.icon_theme = "Papirus-Dark";

    # QSettings (qt5ct/qt6ct's ini backend) parses an unquoted comma-bearing
    # value as a QStringList, not a scalar string — QVariant::toString() on
    # a multi-element QStringList returns "", so qt6ct/qt5ct's
    # readSettings() ends up doing QFont::fromString("") and applying that
    # broken font as the app's actual QGuiApplication::font() (not just a
    # log warning — confirmed via gdb breakpoint on QFont::fromString,
    # called from Qt6CTPlatformTheme::readSettings() at QApplication init,
    # hitting materialgram/coolercontrol). HM's qt module docs say "Fonts
    # must be quoted" — the literal " chars must be part of the ini value.
    qt5ctSettings.Fonts.general = ''"Maple Mono,12,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,Regular"'';
    qt5ctSettings.Fonts.fixed = ''"Maple Mono,12,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,Regular"'';
    qt6ctSettings.Fonts.general = ''"Maple Mono,12,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,Regular"'';
    qt6ctSettings.Fonts.fixed = ''"Maple Mono,12,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,Regular"'';
  };
}
