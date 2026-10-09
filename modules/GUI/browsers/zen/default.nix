{
  inputs,
  lib,
  ...
}: let
  common = import ../gecko-common {inherit lib;};
in {
  imports = [inputs.zen-browser.homeModules.beta];

  programs.zen-browser = {
    enable = true;
    inherit (common) policies;

    profiles.default = {
      settings =
        common.settings
        // {
          "zen.welcome-screen.seen" = true;
          "zen.workspaces.continue-where-left-off" = true;
        };
      search = {
        force = true;
        engines = common.searchEngines;
      };
    };
  };
}
