{
  inputs,
  pkgs,
  ...
}:
let
  ryceeAddons = with inputs.firefox-addons.packages.${pkgs.system}; [
    # === AD BLOCKING & PRIVACY ===
    darkreader
    ublacklist
    ublock-origin

    # === DEVELOPER TOOLS ===
    refined-github

    # === MEDIA & ENTERTAINMENT ===
    fastforwardteam
    return-youtube-dislikes

    # === PRODUCTIVITY & NAVIGATION ===
    indie-wiki-buddy

    # === SYSTEM INTEGRATION ===
    plasma-integration
  ];
in
{
  programs.zen-browser = {
    # Extension packages
    profiles.default.extensions.packages = ryceeAddons;

    # Extension policies and permissions
    policies = {
      "3rdparty".extensions = {
        # uBlock Origin - Enhanced permissions
        "uBlock0@raymondhill.net" = {
          permissions = [
            "internal:privateBrowsingAllowed"
            "internal:svgContextPropertiesAllowed"
          ];
          origins = [ "<all_urls>" ];
        };

        # Movie-web
        "{b0a674f9-f848-9cfd-0feb-583d211308b0}" = {
          permissions = [ "<all_urls>" ];
          origins = [ "<all_urls>" ];
        };

        # GDPR/Cookie consent
        "gdpr@cavi.au.dk" = {
          permissions = [ "<all_urls>" ];
          origins = [ "<all_urls>" ];
        };
      };
    };
  };
}
