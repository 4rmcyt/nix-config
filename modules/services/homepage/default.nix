{
  config,
  pkgs,
  ...
}: {
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
    config.my.network.ports.homepage
  ];

  environment.systemPackages = [pkgs.homepage-dashboard];

  services.homepage-dashboard = {
    enable = true;
    listenPort = config.my.network.ports.homepage;
    # v2's strict host check — Traefik forwards the real Host header. Declared
    # here so it survives even if HOMEPAGE_ALLOWED_HOSTS is dropped from the env.
    allowedHosts = "home.${config.my.defaults.domain}";
    environmentFiles = [config.sops.secrets.homepage_env.path];

    services = import ./services.nix;
    widgets = import ./widgets.nix;
    bookmarks = import ./bookmarks.nix;
    settings = import ./settings.nix;
  };
}
