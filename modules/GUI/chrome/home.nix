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
    extensions = [
      {id = "cjpalhdlnbpafiamejdnhcphjbkeiagm";} # uBlock Origin
      {id = "nngceckbapebfimnlniiiahkandclblb";} # Bitwarden
      {id = "mdjildafknihdffpkfmmpnpoiajfjnjd";} # Proton Pass
    ];
    policies = {
      # Account & sync
      BrowserSignin = 1;
      SyncDisabled = false;
      RestoreOnStartup = 1;

      # Privacy: disable telemetry & UMA reporting
      MetricsReportingEnabled = false;
      DeviceMetricsReportingEnabled = false;
      CloudReportingEnabled = false;
      ReportDeviceCrashReportInfo = false;

      # Privacy: SafeBrowsing — standard only, no enhanced (enhanced uploads URL hashes to Google)
      SafeBrowsingEnabled = true;
      SafeBrowsingProtectionLevel = 1; # 0=off, 1=standard, 2=enhanced

      # Privacy: disable spell-check sending to Google
      SpellCheckServiceEnabled = false;

      # Security: DNS-over-HTTPS via NextDNS
      DnsOverHttpsMode = "automatic";
      DnsOverHttpsTemplates = "https://dns.nextdns.io/nextdns0";

      # Security: WebRTC — only use public IP (prevent internal IP leak)
      WebRtcIPHandling = "default_public_interface_only";

      # Security: force HTTPS on navigation
      HttpsOnlyMode = "force_enabled";

      # Security: disable insecure protocols
      SSLVersionMin = "tls1.2";
      InsecureContentAllowed = {};

      # Security: block mixed content
      DefaultInsecureContentSetting = 2;

      # Lock down: prevent users from changing managed policies
      BrowserLabsEnabled = false;
      CommandLineFlagSecurityWarningsEnabled = true;
    };
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
