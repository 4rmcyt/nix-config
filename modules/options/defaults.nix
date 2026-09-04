# my.defaults.* — identity, locale and a couple of infra scalars used across
# NixOS modules at eval time. Network addresses and ports live in my.network.*
# (modules/options/network.nix). Real values come from the private `private`
# flake input (see modules/options/private-example.nix for the schema); this
# file only declares the options and maps the private data onto them.
{
  lib,
  inputs,
  ...
}: let
  inherit (inputs.private.lib) identity network;
in {
  options.my.defaults = {
    user = lib.mkOption {
      type = lib.types.str;
      description = "Primary username for the system";
    };

    email = lib.mkOption {
      type = lib.types.str;
      description = "Primary email address";
    };

    gitUsername = lib.mkOption {
      type = lib.types.str;
      description = "Git username";
    };

    gitSigningKey = lib.mkOption {
      type = lib.types.str;
      description = "GPG key ID for git commit signing";
    };

    domain = lib.mkOption {
      type = lib.types.str;
      description = "Primary domain for homeserver services";
    };

    timezone = lib.mkOption {
      type = lib.types.str;
      description = "System timezone";
    };

    locale = lib.mkOption {
      type = lib.types.str;
      description = "System locale";
    };

    gcpRelayIp = lib.mkOption {
      type = lib.types.str;
      description = "Public static IP of the GCP relay host";
    };

    nextdnsProfileId = lib.mkOption {
      type = lib.types.str;
      description = "NextDNS account profile ID";
    };
  };

  config.my.defaults = {
    user = lib.mkDefault identity.username;
    email = lib.mkDefault identity.email;
    gitUsername = lib.mkDefault identity.gitUsername;
    gitSigningKey = lib.mkDefault identity.gitSigningKey;
    domain = lib.mkDefault identity.domain;
    timezone = lib.mkDefault identity.timezone;
    locale = lib.mkDefault identity.locale;
    gcpRelayIp = lib.mkDefault network.gcpRelayIp;
    nextdnsProfileId = lib.mkDefault network.nextdns.profileId;
  };
}
