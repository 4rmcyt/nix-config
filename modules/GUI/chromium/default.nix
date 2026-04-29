{
  pkgs,
  config,
  ...
}: {
  sops.secrets = {
    google_api_key = {
      sopsFile = ../../../secrets/common.yaml;
      key = "google_api_key";
      owner = "root";
    };
    google_client_id = {
      sopsFile = ../../../secrets/common.yaml;
      key = "google_client_id";
      owner = "root";
    };
    google_client_secret = {
      sopsFile = ../../../secrets/common.yaml;
      key = "google_client_secret";
      owner = "root";
    };
  };

  sops.templates."google-api-env" = {
    content = ''
      GOOGLE_API_KEY=${config.sops.placeholder.google_api_key}
      GOOGLE_DEFAULT_CLIENT_ID=${config.sops.placeholder.google_client_id}
      GOOGLE_DEFAULT_CLIENT_SECRET=${config.sops.placeholder.google_client_secret}
    '';
    path = "/etc/google-api-env";
    owner = "root";
    mode = "0444";
  };

  environment.extraInit = ''
    set -a
    source /etc/google-api-env
    set +a
  '';

  environment.systemPackages = [
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
      ];
    })
  ];

  programs.chromium = {
    enable = true;
    extraOpts = {
      "BrowserSignin" = 1;
      "SyncDisabled" = false;
      "RestoreOnStartup" = 1;
      "DnsOverHttpsMode" = "automatic";
      "DnsOverHttpsTemplates" = "https://dns.nextdns.io/nextdns0";
    };
  };

  systemd.user.services.chromium-graceful-shutdown = {
    description = "Gracefully shutdown Chromium before session ends";
    wantedBy = ["graphical-session.target"];
    partOf = ["graphical-session.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStop = "${pkgs.procps}/bin/pkill -SIGINT chromium || true";
      TimeoutStopSec = "5s";
    };
  };
}
