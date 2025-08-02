{
  config,
  pkgs,
  lib,
  ...
}:

{
  sops.secrets = {
    redis_password = {
      sopsFile = ../../../secrets/redis.yaml;
      key = "redis_password";
      owner = config.users.users.redis.name;
      group = config.users.groups.redis.name;
      mode = "0400";
    };
  };
  users.users.redis = {
    isSystemUser = true;
    group = "redis";
    extraGroups = [ "users" ];
  };
  users.groups.redis = { };

  networking.firewall.allowedTCPPorts = [
    6379 # Redis
  ];

  services.redis = {
    servers.redis = {
      enable = true;
      requirepass = config.sops.secrets.redis_password.path;
    };
  };
}
