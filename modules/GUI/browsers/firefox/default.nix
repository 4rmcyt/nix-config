{lib, ...}: let
  common = import ../gecko-common {inherit lib;};
in {
  imports = [
    ./preferences.nix
    ./ui.nix
  ];

  programs.firefox = {
    enable = true;
    configPath = ".mozilla/firefox";
    inherit (common) policies;
    profiles.default = {
      inherit (common) settings;
      search.engines = common.searchEngines;
    };
  };

  home.file.".mozilla/firefox/profiles.ini".force = lib.mkForce true;
  home.file.".mozilla/firefox/default/search.json.mozlz4".force = lib.mkForce true;
}
