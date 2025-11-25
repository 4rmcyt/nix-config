{
  config,
  pkgs,
  ...
}: let
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
in {
  sops.secrets = {
    microbin_admin_password = {
      sopsFile = ../../../secrets/microbin.yaml;
      key = "admin_password";
      owner = config.users.users.microbin.name;
      group = config.users.groups.microbin.name;
      mode = "0400";
    };
    microbin_uploader_password = {
      sopsFile = ../../../secrets/microbin.yaml;
      key = "uploader_password";
      owner = config.users.users.microbin.name;
      group = config.users.groups.microbin.name;
      mode = "0400";
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
  systemd.services.microbin = {
    serviceConfig = {
      LoadCredential = [
        "admin_password:${config.sops.secrets.microbin_admin_password.path}"
        "uploader_password:${config.sops.secrets.microbin_uploader_password.path}"
      ];
      ExecStart = let
        startScript = pkgs.writeShellScript "microbin-start" ''
          export MICROBIN_ADMIN_PASSWORD=$(cat ''${CREDENTIALS_DIRECTORY}/admin_password)
          export MICROBIN_UPLOADER_PASSWORD=$(cat ''${CREDENTIALS_DIRECTORY}/uploader_password)
          exec ${pkgs.microbin}/bin/microbin
        '';
      in pkgs.lib.mkForce "${startScript}";
    };
  };

  services = {
    microbin = {
      enable = true;
      settings = {
        MICROBIN_WIDE = true;
        MICROBIN_MAX_FILE_SIZE_UNENCRYPTED_MB = 2048;
        MICROBIN_PUBLIC_PATH = "https://microbin.${config.my.defaults.domain}";
        MICROBIN_BIND = "127.0.0.1";
        MICROBIN_PORT = 8069;
        MICROBIN_HIDE_LOGO = false;
        MICROBIN_HIGHLIGHTSYNTAX = true;
        MICROBIN_HIDE_HEADER = false;
        MICROBIN_HIDE_FOOTER = false;
        MICROBIN_ADMIN_USERNAME = "admin";
      };
    };

    nginx = {
      enable = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts."microbin.${config.my.defaults.domain}" = {
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
