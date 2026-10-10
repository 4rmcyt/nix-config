{
  osConfig ? null,
  config,
  lib,
  pkgs,
  ...
}: let
  baseExtensions = import ./extensions.nix {inherit pkgs;};
  baseSettings = import ./settings.nix {inherit osConfig config lib;};

  mkProfile = profile: {
    extensions = baseExtensions ++ profile.extensions;
    userSettings = lib.recursiveUpdate baseSettings profile.settings;
    mutableUserSettings = true;
  };
in {
  imports = [
    ./ai.nix
  ];

  programs.vscodium = {
    enable = true;
    package = pkgs.vscodium;

    profiles = lib.mapAttrs (_: mkProfile) {
      default = {
        extensions = [];
        settings = {};
      };
      python = import ./profiles/python.nix {inherit pkgs;};
      web = import ./profiles/web.nix {inherit pkgs;};
      infra = import ./profiles/infra.nix {inherit pkgs;};
    };
  };
}
