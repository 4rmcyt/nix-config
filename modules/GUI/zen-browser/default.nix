{
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    ./extensions.nix
    ./policies.nix
    ./preferences.nix
    inputs.zen-browser.homeModules.beta
  ];

  home.sessionVariables = {
    # Improved Wayland support
    MOZ_ENABLE_WAYLAND = 1;
    MOZ_WEBRENDER = 1;
    MOZ_USE_XINPUT2 = 1;
    MOZ_DISABLE_RDD_SANDBOX = 1;
    MOZ_DRM_DEVICE = "/dev/dri/renderD128";
  };

  programs.zen-browser = {
    enable = true;
    nativeMessagingHosts = [
      pkgs.browserpass
      pkgs.kdePackages.plasma-browser-integration
    ];
    profiles.default =
      let
        containers = {
          Work = {
            color = "blue";
            icon = "briefcase";
            id = 1;
          };
          Shopping = {
            color = "yellow";
            icon = "dollar";
            id = 2;
          };
        };
      in
      {
        settings = {
          "zen.workspaces.continue-where-left-off" = true;
          "zen.workspaces.natural-scroll" = true;
          "zen.view.compact.hide-tabbar" = true;
          "zen.view.compact.hide-toolbar" = true;
          "zen.view.compact.animate-sidebar" = false;
          "zen.welcome-screen.seen" = true;
        };

        bookmarks = {
          force = true;
          settings = [
            {
              name = "Nix sites";
              toolbar = true;
              bookmarks = [
                {
                  name = "homepage";
                  url = "https://nixos.org/";
                }
                {
                  name = "wiki";
                  tags = [
                    "wiki"
                    "nix"
                  ];
                  url = "https://wiki.nixos.org/";
                }
              ];
            }
          ];
        };

        containersForce = true;
        inherit containers;

        search = {
          force = true;
          default = "google";
          engines =
            let
              nixSnowflakeIcon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
            in
            {
              "Nix Packages" = {
                urls = [
                  {
                    template = "https://search.nixos.org/packages";
                    params = [
                      {
                        name = "type";
                        value = "packages";
                      }
                      {
                        name = "channel";
                        value = "unstable";
                      }
                      {
                        name = "query";
                        value = "{searchTerms}";
                      }
                    ];
                  }
                ];
                icon = nixSnowflakeIcon;
                definedAliases = [ "np" ];
              };
              "Nix Options" = {
                urls = [
                  {
                    template = "https://search.nixos.org/options";
                    params = [
                      {
                        name = "channel";
                        value = "unstable";
                      }
                      {
                        name = "query";
                        value = "{searchTerms}";
                      }
                    ];
                  }
                ];
                icon = nixSnowflakeIcon;
                definedAliases = [ "nop" ];
              };
              "Home Manager Options" = {
                urls = [
                  {
                    template = "https://home-manager-options.extranix.com/";
                    params = [
                      {
                        name = "query";
                        value = "{searchTerms}";
                      }
                      {
                        name = "release";
                        value = "master"; # unstable
                      }
                    ];
                  }
                ];
                icon = nixSnowflakeIcon;
                definedAliases = [ "hmop" ];
              };
              bing.metaData.hidden = "true";
            };
        };
      };
  };
}
