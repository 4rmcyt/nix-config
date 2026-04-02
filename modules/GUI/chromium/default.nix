{
  pkgs,
  config,
  ...
}:
{
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

  environment.extraInit = ''
    export GOOGLE_API_KEY="$(cat ${config.sops.secrets.google_api_key.path})"
    export GOOGLE_DEFAULT_CLIENT_ID="$(cat ${config.sops.secrets.google_client_id.path})"
    export GOOGLE_DEFAULT_CLIENT_SECRET="$(cat ${config.sops.secrets.google_client_secret.path})"
  '';

  environment.systemPackages = [
    (pkgs.chromium.override {
      enableWideVine = true;
      commandLineArgs = [
        "--enable-features=Vulkan,DefaultANGLEVulkan,VulkanFromANGLE"
        "--ignore-gpu-blocklist"
        "--use-angle=vulkan"
        "--ozone-platform=wayland"
        "--disable-features=WaylandOverlayDelegation"
        "--enable-features=UseSkiaRenderer"
        "--enable-smooth-scrolling"
        "--enable-gpu-rasterization"
        "--enable-zero-copy"
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
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStop = "${pkgs.procps}/bin/pkill -SIGINT chromium || true";
      TimeoutStopSec = "5s";
    };
  };
}
