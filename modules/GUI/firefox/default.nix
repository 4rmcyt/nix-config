{
  lib,
  pkgs,
  ...
}: let
  moz = short: "https://addons.mozilla.org/firefox/downloads/latest/${short}/latest.xpi";
in {
  imports = [
    ./policies.nix
    ./preferences.nix
    ./searchEngines.nix
    ./ui.nix
  ];

  programs.firefox = {
    enable = true;
    configPath = ".mozilla/firefox";

    policies.ExtensionSettings = {
      # === AD BLOCKING & PRIVACY ===
      "addon@darkreader.org" = {
        install_url = moz "darkreader";
        installation_mode = "force_installed";
      };

      "uBlock0@raymondhill.net" = {
        install_url = moz "ublock-origin";
        installation_mode = "force_installed";
      };

      # === DEVELOPER TOOLS ===
      "{a4c4eda4-fb84-4a84-b4a1-f7c1cbf2a1ad}" = {
        install_url = moz "refined-github-";
        installation_mode = "force_installed";
      };

      # === MEDIA & ENTERTAINMENT ===
      "{762f9885-5a13-4abd-9c77-433dcd38b8fd}" = {
        install_url = moz "return-youtube-dislikes";
        installation_mode = "force_installed";
      };

      # === PRODUCTIVITY & NAVIGATION ===
      "indie-wiki-buddy@einaregilsson.com" = {
        install_url = moz "indie-wiki-buddy";
        installation_mode = "force_installed";
      };
    };
  };

  home.file.".mozilla/firefox/profiles.ini".force = lib.mkForce true;
  home.file.".mozilla/firefox/default/search.json.mozlz4".force = lib.mkForce true;
}
