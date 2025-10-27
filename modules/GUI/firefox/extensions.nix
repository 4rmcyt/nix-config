{
  inputs,
  pkgs,
  ...
}: let
  ryceeAddons = with inputs.firefox-addons.packages.${pkgs.system}; [
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
