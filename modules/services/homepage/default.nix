{
  config,
  pkgs,
  ...
}: {
  # SOPS secret for homepage environment file
  sops.secrets.homepage_env = {
    sopsFile = ../../../secrets/homepage.env;
    format = "dotenv";
  };

  users.users.homepage-dashboard = {
    isSystemUser = true;
    group = "homepage-dashboard";
    extraGroups = ["users"];
  };
  users.groups.homepage-dashboard = {};

  networking.firewall.allowedTCPPorts = [
    8082 # Homepage Dashboard
  ];

  environment.systemPackages = [pkgs.homepage-dashboard];

  services.homepage-dashboard = {
    enable = true;
    listenPort = 8082;
    environmentFiles = [config.sops.secrets.homepage_env.path];

    # Import modular configuration
    services = import ./services.nix;
    widgets = import ./widgets.nix;
    bookmarks = import ./bookmarks.nix;
    settings = import ./settings.nix;
  };
}
