{
  pkgs,
  lib,
  osConfig,
  ...
}: {
  xdg.configFile."chromium/policies/managed/hardening.json".text = lib.generators.toJSON {} {
    BrowserSignin = 1;
    SyncDisabled = false;
    RestoreOnStartup = 1;
    MetricsReportingEnabled = false;
    CloudReportingEnabled = false;
    SafeBrowsingEnabled = true;
    SafeBrowsingProtectionLevel = 1;
    SpellCheckServiceEnabled = false;
    DnsOverHttpsMode = "automatic";
    DnsOverHttpsTemplates = "https://dns.nextdns.io/${osConfig.my.defaults.nextdnsProfileId}";
    WebRtcIPHandling = "default_public_interface_only";
    HttpsOnlyMode = "force_enabled";
    SSLVersionMin = "tls1.2";
    DefaultInsecureContentSetting = 2;
  };

  home.packages = [
    (pkgs.chromium.override {
      enableWideVine = true;
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
        "--no-wifi"
      ];
    })
  ];

  systemd.user.services.chromium-graceful-shutdown = {
    Unit = {
      Description = "Gracefully shutdown Chromium before session ends";
      PartOf = ["graphical-session.target"];
    };
    Install.WantedBy = ["graphical-session.target"];
    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStop = "${pkgs.procps}/bin/pkill -SIGINT chromium || true";
      TimeoutStopSec = "5s";
    };
  };
}
