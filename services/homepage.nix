{ config, pkgs, lib, ... }:

{
  # Homepage is now configured using a single, declarative settings file
  # managed by sops-nix. This is a cleaner and more reliable approach.
  services.homepage-dashboard = {
    enable = true;
    listenPort = 8082;

    # This option points Homepage to the decrypted YAML configuration file.
    # All your layout, widgets, and secrets are now managed in that single file.
    settingsFile = config.sops.secrets.homepage_settings.path;
  };
}
