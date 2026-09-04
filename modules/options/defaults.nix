# my.defaults.* — identity/locale/network scalars used across NixOS modules at
# eval time. Real values come from the private `private` flake input (see
# parts/private-example.nix for the schema); this file only declares the options
# and maps the private data onto them.
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

    fullName = lib.mkOption {
      type = lib.types.str;
      description = "Owner's full name (git author, mail realName)";
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

    gateway = lib.mkOption {
      type = lib.types.str;
      description = "Default gateway IP address";
    };

    homeserver_lan = lib.mkOption {
      type = lib.types.str;
      description = "Local IP address of the homeserver";
    };

    desktop_lan = lib.mkOption {
      type = lib.types.str;
      description = "Local IP address of the desktop LAN connection";
    };

    desktop_wifi = lib.mkOption {
      type = lib.types.str;
      description = "Local IP address of the desktop WiFi connection";
    };

    matebook_wifi = lib.mkOption {
      type = lib.types.str;
      description = "Local IP address of the Matebook WiFi connection";
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
    fullName = lib.mkDefault identity.fullName;
    gitUsername = lib.mkDefault identity.gitUsername;
    gitSigningKey = lib.mkDefault identity.gitSigningKey;
    domain = lib.mkDefault identity.domain;
    timezone = lib.mkDefault identity.timezone;
    locale = lib.mkDefault identity.locale;
    gateway = lib.mkDefault network.gateway;
    homeserver_lan = lib.mkDefault network.hosts.homeserver_lan;
    desktop_lan = lib.mkDefault network.hosts.desktop_lan;
    desktop_wifi = lib.mkDefault network.hosts.desktop_wifi;
    matebook_wifi = lib.mkDefault network.hosts.matebook_wifi;
    gcpRelayIp = lib.mkDefault network.gcpRelayIp;
    nextdnsProfileId = lib.mkDefault network.nextdns.profileId;
  };
}
