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

  environment.systemPackages = [pkgs.homepage-dashboard];

  services.homepage-dashboard = {
    enable = true;
    listenPort = config.my.network.ports.homepage;

    allowedHosts = "home.${config.my.defaults.domain}";
    environmentFiles = [config.sops.secrets.homepage_env.path];

    services = import ./services.nix {inherit config;};
    widgets = import ./widgets.nix;
    bookmarks = import ./bookmarks.nix;
    settings = import ./settings.nix;
  };
}
