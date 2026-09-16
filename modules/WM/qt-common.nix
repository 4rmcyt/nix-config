{
  qt = {
    enable = true;
    platformTheme.name = "qtct";
    style.name = "kvantum";
    qt5ctSettings.Appearance.icon_theme = "Papirus-Dark";
    qt6ctSettings.Appearance.icon_theme = "Papirus-Dark";

    # Must be quoted: QSettings parses an unquoted comma-bearing value as a QStringList,
    # and QVariant::toString() on that returns "", silently applying a broken font
    # (confirmed via gdb, hitting materialgram/coolercontrol).
    qt5ctSettings.Fonts.general = ''"Maple Mono,12,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,Regular"'';
    qt5ctSettings.Fonts.fixed = ''"Maple Mono,12,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,Regular"'';
    qt6ctSettings.Fonts.general = ''"Maple Mono,12,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,Regular"'';
    qt6ctSettings.Fonts.fixed = ''"Maple Mono,12,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,Regular"'';
  };
}
