{
  config,
  pkgs,
  lib,
  ...
}:
let
  nordHighlight = builtins.toFile "nord.css" (builtins.readFile ./nord.css);
  nordUi = builtins.toFile "nord_ui.css" (builtins.readFile ./nord_ui.css);
  highlightJsNix = pkgs.fetchurl {
    url = "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.11.1/languages/nix.min.js";
    hash = "sha256-j4dmtrr8qUODoICuOsgnj1ojTAmxbKe00mE5sfElC/I=";
  };
  highlightJs = pkgs.fetchurl {
    url = "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.11.1/highlight.min.js";
    hash = "sha256-xKOZ3W9Ii8l6NUbjR2dHs+cUyZxXuUcxVMb7jSWbk4E=";
  };
in
{

  sops.secrets = {
    miniflux_db_password = {
      sopsFile = ../../../secrets/postgresql.yaml;
      key = "miniflux_db_password";
      owner = config.users.users.postgresql.name;
      group = config.users.groups.postgresql.name;
      mode = "0400";
    };
    miniflux_admin_creds = {
      sopsFile = ../../../secrets/miniflux.env;
      key = "miniflux_admin_creds";
      owner = config.users.users.miniflux.name;
      group = config.users.groups.miniflux.name;
      mode = "0600";
      format = "dotenv";
    };
  };

  users.users.microbin = {
    isSystemUser = true;
    group = "microbin";
    extraGroups = ["users"];
  };
  users.groups.microbin = {};

  networking.firewall.allowedTCPPorts = [
    8069 # Microbin
  ];

  nixpkgs.overlays = [
    (_final: prev: {
      microbin = prev.microbin.overrideAttrs (
        _finalAttrs: _previousAttrs: {
          postPatch = ''
            cp ${nordHighlight} templates/assets/highlight/highlight.min.css
            cp ${highlightJs} templates/assets/highlight/highlight.min.js
            cp ${highlightJsNix} templates/assets/highlight/nix.min.js
            echo "" >> templates/assets/water.css
            cat ${nordUi} >> templates/assets/water.css
            sed -i "s#<option value=\"auto\">#<option value=\"auto\" selected>#" templates/index.html
            sed -i "s#highlight.min.js\"></script>#highlight.min.js\"></script><script type=\"text/javascript\" src=\"{{ args.public_path_as_str() }}/static/highlight/nix.min.js\"></script>#" templates/upload.html
          '';
        }
      );
    })
  ];
  services = {
    microbin = {
      enable = true;
      settings = {
        MICROBIN_WIDE = true;
        MICROBIN_MAX_FILE_SIZE_UNENCRYPTED_MB = 2048;
        MICROBIN_PUBLIC_PATH = "https://miniflux.${config.my.defaults.domain}";
        MICROBIN_BIND = "127.0.0.1";
        MICROBIN_PORT = 8069;
        MICROBIN_HIDE_LOGO = true;
        MICROBIN_HIGHLIGHTSYNTAX = true;
        MICROBIN_HIDE_HEADER = true;
        MICROBIN_HIDE_FOOTER = true;
      };
    };
    passwordFile = lib.literalExpression ''
      pkgs.writeText "microbin-secret.txt" '''
        MICROBIN_ADMIN_USERNAME
        MICROBIN_ADMIN_PASSWORD
        MICROBIN_UPLOADER_PASSWORD
      '''
    '';

    nginx = {
      enable = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts."miniflux.${config.my.defaults.domain}" = {
        forceSSL = true;
        sslCertificate = config.my.security.ssl.certPath;
        sslCertificateKey = config.my.security.ssl.keyPath;
        locations."/" = {
          proxyPass = "http://localhost:8069";
          proxyWebsockets = true;
        };
      };
    };
  };
}
