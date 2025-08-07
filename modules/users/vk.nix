{
  config,
  inputs,
  pkgs,
  lib,
  ...
}:
let
  user-ed25519 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAokdbrMinZjhDnVLnrXOjNn9SvzsPdlP6P3T9hAtGG8 vk@Volodymyr-Kondratenko-Mac.local";
  user-rsa = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDc3zaVdT+TBJdjBWbN2fwSricHc7yJFGPxB9PB2sR4mkCmv6FPBd8vGZ1pYLJWEqgPU0C76IWAiSpwRrYu4Da0JKyEITh69sT+ndufTsrXJwPPxFKsUnmm2XQE0O2M2dM3wx+sMnBxWc1AMlfkWDnpP2N1Rl33ridumzEAGvJGqrn/ScpHGSgEkpZwVAnO5U8S9EjuO0h+nUJUSfLJVcl/cLeqHuF5zE8mSxsrj1FjiymZSquOEVAwNOhbCLuFVsYSEb8qujFsD7M9Umd0qvPQwCY9zN/Hb37TrNebhJ32kjIOlrWO3fnreMetIVRtTC1/cvKnGV16S32/YGiIUb2zLTfxKp2bn2qvXgLwocKf/M56fobQ6LOt60dUG1y3QwRLI1uAQggzp2N3/shQRb89nCQ/Zq67h941U2Z/RnNx7Hzl6n9DHkiKmkvXQuld0DWgh6wwG775gR2wBZHgpqtLqoRhwFVrvwIL9UkrLL4PE9A5iBEmypWsCWUomi5St+k= vk@Volodymyr-Kondratenko-Mac.local";

  user-keys = [
    user-ed25519
    user-rsa
  ];
in
{
  users.users.vk = {
    name = "vk";
    home = "/Users/vk";
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = user-keys;
  };

  programs.zsh.enable = true;

  nix.settings.trusted-users = [
    "vk"
    "@admin"
  ];

  #   services.redis.servers.default = {
  #   enable = true;

  #   # Security settings
  #   bind = "127.0.0.1";  # Only local connections
  #   port = 6379;

  #   # Authentication
  #   requirePass = "$(cat ${config.sops.secrets.redis-password.path})";

  #   # Resource limits
  #   maxmemory = "512MB";
  #   maxmemoryPolicy = "allkeys-lru";

  #   # Disable dangerous commands
  #   rename-command = {
  #     FLUSHDB = "";
  #     FLUSHALL = "";
  #     KEYS = "";
  #     PEXPIRE = "";
  #     DEL = "";
  #     CONFIG = "";
  #     SHUTDOWN = "";
  #     DEBUG = "";
  #     EVAL = "";
  #   };

  #   # Logging
  #   logLevel = "warning";
  #   syslogEnabled = true;

  #   # Persistence settings
  #   save = [
  #     "900 1"   # Save after 900s if at least 1 key changed
  #     "300 10"  # Save after 300s if at least 10 keys changed
  #     "60 10000" # Save after 60s if at least 10000 keys changed
  #   ];

  #   # Append-only file
  #   appendOnly = true;
  #   appendFsync = "everysec";
  # };

  # # Add SOPS secret for Redis
  # sops.secrets.redis-password = {
  #   sopsFile = ../../../secrets/services.yaml;
  #   owner = "redis";
  #   group = "redis";
  #   mode = "0400";
  # };

  # # Systemd security hardening
  # systemd.services.redis-default.serviceConfig = {
  #   # Resource limits
  #   MemoryMax = "600M";
  #   CPUQuota = "50%";

  #   # Security hardening
  #   NoNewPrivileges = true;
  #   PrivateTmp = true;
  #   ProtectHome = true;
  #   ProtectSystem = "strict";
  #   ReadWritePaths = [ "/var/lib/redis-default" ];

  #   # Network restrictions
  #   RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ];

  #   # Capabilities
  #   CapabilityBoundingSet = "";
  #   AmbientCapabilities = "";
  # };
}
