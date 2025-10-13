{
  inputs,
  pkgs,
  ...
}: let
  ryceeAddons = with inputs.firefox-addons.packages.${pkgs.system}; [
    # === AD BLOCKING & PRIVACY ===
    darkreader
    ublock-origin
    ublacklist
    terms-of-service-didnt-read

    # === DEVELOPER TOOLS ===
    refined-github

    # === MEDIA & ENTERTAINMENT ===
    fastforwardteam
    return-youtube-dislikes

    # === PRODUCTIVITY & NAVIGATION ===
    indie-wiki-buddy
    linkwarden

    # === SYSTEM INTEGRATION ===
    plasma-integration
  ];
in {
  programs.firefox.profiles.default.extensions.packages = ryceeAddons;

  programs.firefox.policies."3rdparty".extensions = {
    # uBlock Origin - Enhanced permissions
    "uBlock0@raymondhill.net" = {
      permissions = [
        "internal:privateBrowsingAllowed"
        "internal:svgContextPropertiesAllowed"
      ];
      origins = ["<all_urls>"];
    };

    # GDPR/Cookie consent
    "gdpr@cavi.au.dk" = {
      permissions = ["<all_urls>"];
      origins = ["<all_urls>"];
    };
  };
}
