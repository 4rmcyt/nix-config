_: {
  programs.zen-browser.profiles.default.search.engines = {
    # === DISABLE DEFAULT SEARCH ENGINE SUGGESTIONS ===
    "ddg".metaData.hidden = true;
    "bing".metaData.hidden = true;
    "ebay".metaData.hidden = true;
    "amazondotcom-us".metaData.hidden = true;
    "wikipedia".metaData.hidden = true;

    # === GITHUB SEARCH ENGINES ===
    "Github Search Nix" = {
      urls = [
        {
          template = "https://github.com/search?type=code&q=lang:nix+NOT+is:fork+{searchTerms}";
        }
      ];
      icon = "https://github.com/favicon.ico";
      definedAliases = ["@gn"];
    };

    "Github Search" = {
      urls = [
        {
          template = "https://github.com/search?type=code&q=NOT+is:fork+{searchTerms}";
        }
      ];
      icon = "https://github.com/favicon.ico";
      definedAliases = ["@gh"];
    };

    "Github Search Fish" = {
      urls = [
        {
          template = "https://github.com/search?type=code&q=lang:fish+NOT+is:fork+{searchTerms}";
        }
      ];
      icon = "https://fishshell.com/favicon.ico";
      definedAliases = ["@gf"];
    };

    "Github Search Lua" = {
      urls = [
        {
          template = "https://github.com/search?type=code&q=lang:lua+NOT+is:fork+{searchTerms}";
        }
      ];
      icon = "https://github.com/favicon.ico";
      definedAliases = ["@gl"];
    };

    "Github Search Gleam" = {
      urls = [
        {
          template = "https://github.com/search?type=code&q=lang:gleam+NOT+is:fork+{searchTerms}";
        }
      ];
      icon = "https://github.com/favicon.ico";
      definedAliases = ["@gg"];
    };

    "Github Search Typst" = {
      urls = [
        {
          template = "https://github.com/search?type=code&q=lang:typst+NOT+is:fork+{searchTerms}";
        }
      ];
      icon = "https://github.com/favicon.ico";
      definedAliases = ["@gt"];
    };

    # === NIX ECOSYSTEM SEARCH ENGINES ===
    "Noogle" = {
      urls = [
        {
          template = "https://noogle.dev/q?term={searchTerms}";
        }
      ];
      icon = "https://noogle.dev/favicon.png";
      definedAliases = ["@ng"];
    };

    "Nixpkgs" = {
      urls = [
        {
          template = "https://github.com/search?type=code&q=repo:NixOS/nixpkgs+lang:nix+{searchTerms}";
        }
      ];
      definedAliases = ["@npkgs"];
    };

    "Home Manager" = {
      urls = [
        {
          template = "https://github.com/search?type=code&q=repo:nix-community/home-manager+lang:nix+{searchTerms}";
        }
      ];
      definedAliases = ["@hmgr"];
    };

    "Home Manager Options" = {
      urls = [
        {
          template = "https://home-manager-options.extranix.com/?release=release-24.11&query={searchTerms}";
        }
      ];
      icon = "https://home-manager-options.extranix.com/images/favicon.png";
      definedAliases = ["@oh"];
    };

    "NixOS Options" = {
      urls = [
        {
          template = "https://search.nixos.org/options?channel=24.11&from=0&size=100&sort=alpha_asc&query={searchTerms}";
        }
      ];
      definedAliases = ["@on"];
    };
  };
}
