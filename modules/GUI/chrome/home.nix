{pkgs, ...}: {
  programs.chromium = {
    enable = true;
    package = pkgs.google-chrome;
    commandLineArgs = [
      "--ozone-platform-hint=auto"
      "--ignore-gpu-blocklist"
      "--enable-features=AcceleratedVideoDecodeLinuxGL,AcceleratedVideoDecodeLinuxZeroCopyGL,VaapiIgnoreDriverChecks,WaylandWindowDecorations"
      "--disable-features=WaylandOverlayDelegation,UseChromeOSDirectVideoDecoder"
      "--disable-gpu-process-crash-limit"
      "--enable-smooth-scrolling"
      "--enable-gpu-rasterization"
      "--gtk-version=4"
      "--force-dark-mode"
    ];
  };

  systemd.user.services.chrome-graceful-shutdown = {
    Unit = {
      Description = "Gracefully shutdown Chrome before session ends";
      PartOf = ["graphical-session.target"];
    };
    Install.WantedBy = ["graphical-session.target"];
    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStop = "${pkgs.procps}/bin/pkill -SIGINT chrome || true";
      TimeoutStopSec = "5s";
    };
  };
}
