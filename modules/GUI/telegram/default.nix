{pkgs, ...}: {
  home.packages = with pkgs; [
    ayugram-desktop
  ];

  # AyuGram starts in system tray by default
  # Click the tray icon to show the window
}
