{
  inputs,
  pkgs,
  ...
}:
let
  # Search extension names with below command:
  # nix flake show --json "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons" --all-systems | jq -r '.packages."x86_64-linux" | keys[]' | rg QUERY
  ryceeAddons = with inputs.firefox-addons.packages.${pkgs.system}; [
    ublock-origin
    return-youtube-dislikes
    indie-wiki-buddy
    refined-github
    undoclosetabbutton
    movie-web
    tree-style-tab
    terms-of-service-didnt-read
    auto-tab-discard
    redirector # For nixos wiki
    darkreader
    plasma-integration
  ];

  customAddons = [
  ];
in
{
  programs.firefox.profiles.default = {
    extensions.packages = ryceeAddons ++ customAddons;
  };

  programs.firefox.policies."3rdparty".extensions = {
    "uBlock0@raymondhill.net" = {
      permissions = [ "internal:privateBrowsingAllowed" ];
      origins = [ ];
    };

    # Movie-web
    "{b0a674f9-f848-9cfd-0feb-583d211308b0}" = {
      "permissions" = [ "<all_urls>" ];
      "origins" = [ "<all_urls>" ];
    };

    "gdpr@cavi.au.dk" = {
      "permissions" = [ "<all_urls>" ];
      "origins" = [ "<all_urls>" ];
    };
  };
}
