{
  config,
  pkgs,
  lib,
  ...
}:

{
  services.redis = {
    enable = true;
    package = pkgs.redis.overrideAttrs (oldAttrs: {
      doCheck = false; # Disable tests to speed up build
    });
    settings = {
      bind = "127.0.0.1:6379";
      protected-mode = "yes";
      dir = "/var/lib/redis";
      user = "redis";
      group = "redis";
      maxmemory = "256mb"; # Limit memory usage
      maxmemory-policy = "allkeys-lru"; # Evict least recently used keys
      appendonly = "yes"; # Enable AOF for persistence
      appendfsync = "everysec"; # Sync every second
      save = [
        "900 1"
        "300 10"
        "60 10000"
      ]; # Save snapshots
      requirepass = config.sops.secrets.redis_password.path; # Use a secure password
    };
  };
  services.nginx.virtualHosts."redis.labhome.work" = {
    forceSSL = true;
    enableACME = true;
    http2 = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    recommendedProxyHeaders = true;
    recommendedProxyHeadersForWebsockets = true;
    recommendedSecurityHeaders = true;
    locations."/" = {
      proxyPass = "http://localhost:6379";
      proxyWebsockets = true;
    };
  };
  networking.firewall.allowedTCPPorts = [
    6379 # Redis
  ];
  sops.secrets = {
    redis_password = {
      owner = config.users.users.redis.name;
      group = config.users.groups.redis.name;
      mode = "0400"; # Read-only for owner
    };
  };
}
