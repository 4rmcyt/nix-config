{
  config,
  pkgs,
  ...
}: {
  sops.secrets = {
    cloudflare_tunnel_credentials = {
      sopsFile = ../../../secrets/cloudflare_tunnel_credentials.bin;
      key = "credentials";
      owner = config.users.users.cloudflared.name;
      group = config.users.groups.cloudflared.name;
      mode = "0400";
      format = "binary";
    };

    # Tunnel configuration
    tunnel_id = {
      sopsFile = ../../../secrets/cloudflared.yaml;
      key = "tunnel_id";
      owner = config.users.users.cloudflared.name;
      group = config.users.groups.cloudflared.name;
    };
    domain = {
      sopsFile = ../../../secrets/cloudflared.yaml;
      key = "domain";
    };

    # Service domains
    jellyfin_domain = {
      sopsFile = ../../../secrets/cloudflared.yaml;
      key = "jellyfin_domain";
    };
    audiobookshelf_domain = {
      sopsFile = ../../../secrets/cloudflared.yaml;
      key = "audiobookshelf_domain";
    };
    kavita_domain = {
      sopsFile = ../../../secrets/cloudflared.yaml;
      key = "kavita_domain";
    };
    tdarr_domain = {
      sopsFile = ../../../secrets/cloudflared.yaml;
      key = "tdarr_domain";
    };
    transmission_domain = {
      sopsFile = ../../../secrets/cloudflared.yaml;
      key = "transmission_domain";
    };
    sonarr_domain = {
      sopsFile = ../../../secrets/cloudflared.yaml;
      key = "sonarr_domain";
    };
    radarr_domain = {
      sopsFile = ../../../secrets/cloudflared.yaml;
      key = "radarr_domain";
    };
    lidarr_domain = {
      sopsFile = ../../../secrets/cloudflared.yaml;
      key = "lidarr_domain";
    };
    readarr_domain = {
      sopsFile = ../../../secrets/cloudflared.yaml;
      key = "readarr_domain";
    };
    bazarr_domain = {
      sopsFile = ../../../secrets/cloudflared.yaml;
      key = "bazarr_domain";
    };
    prowlarr_domain = {
      sopsFile = ../../../secrets/cloudflared.yaml;
      key = "prowlarr_domain";
    };
    jellyseerr_domain = {
      sopsFile = ../../../secrets/cloudflared.yaml;
      key = "jellyseerr_domain";
    };
    paperless_domain = {
      sopsFile = ../../../secrets/cloudflared.yaml;
      key = "paperless_domain";
    };
    miniflux_domain = {
      sopsFile = ../../../secrets/cloudflared.yaml;
      key = "miniflux_domain";
    };
    cal_domain = {
      sopsFile = ../../../secrets/cloudflared.yaml;
      key = "cal_domain";
    };
    home_domain = {
      sopsFile = ../../../secrets/cloudflared.yaml;
      key = "home_domain";
    };
    link_domain = {
      sopsFile = ../../../secrets/cloudflared.yaml;
      key = "link_domain";
    };
    flare_domain = {
      sopsFile = ../../../secrets/cloudflared.yaml;
      key = "flare_domain";
    };
    grafana_domain = {
      sopsFile = ../../../secrets/cloudflared.yaml;
      key = "grafana_domain";
    };
    kuma_domain = {
      sopsFile = ../../../secrets/cloudflared.yaml;
      key = "kuma_domain";
    };
    hass_domain = {
      sopsFile = ../../../secrets/cloudflared.yaml;
      key = "hass_domain";
    };
    vault_domain = {
      sopsFile = ../../../secrets/cloudflared.yaml;
      key = "vault_domain";
    };
    auth_domain = {
      sopsFile = ../../../secrets/cloudflared.yaml;
      key = "auth_domain";
    };
    ollama_domain = {
      sopsFile = ../../../secrets/cloudflared.yaml;
      key = "ollama_domain";
    };

    # Internal configuration
    localhost = {
      sopsFile = ../../../secrets/cloudflared.yaml;
      key = "localhost";
    };
    homeserver_host = {
      sopsFile = ../../../secrets/cloudflared.yaml;
      key = "homeserver_host";
    };
    default_response = {
      sopsFile = ../../../secrets/cloudflared.yaml;
      key = "default_response";
    };
  };

  users.users.cloudflared = {
    isSystemUser = true;
    group = "cloudflared";
    extraGroups = ["users"];
  };
  users.groups.cloudflared = {};

  # Generate cloudflared configuration dynamically
  systemd.services.cloudflared-config-generator = {
    description = "Generate Cloudflared configuration with secrets";
    wantedBy = ["cloudflared.service"];
    before = ["cloudflared.service"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = config.users.users.cloudflared.name;
      Group = config.users.groups.cloudflared.name;
      ExecStartPre = "+${pkgs.coreutils}/bin/mkdir -p /var/lib/cloudflared/config";
    };
    script = ''
      # Config directory is created by ExecStartPre as root

      # Read secrets
      TUNNEL_ID=$(cat ${config.sops.secrets.tunnel_id.path})
      LOCALHOST=$(cat ${config.sops.secrets.localhost.path})
      HOMESERVER_HOST=$(cat ${config.sops.secrets.homeserver_host.path})
      DEFAULT_RESPONSE=$(cat ${config.sops.secrets.default_response.path})

      # Read all domain secrets
      JELLYFIN_DOMAIN=$(cat ${config.sops.secrets.jellyfin_domain.path})
      AUDIOBOOKSHELF_DOMAIN=$(cat ${config.sops.secrets.audiobookshelf_domain.path})
      KAVITA_DOMAIN=$(cat ${config.sops.secrets.kavita_domain.path})
      TDARR_DOMAIN=$(cat ${config.sops.secrets.tdarr_domain.path})
      TRANSMISSION_DOMAIN=$(cat ${config.sops.secrets.transmission_domain.path})
      SONARR_DOMAIN=$(cat ${config.sops.secrets.sonarr_domain.path})
      RADARR_DOMAIN=$(cat ${config.sops.secrets.radarr_domain.path})
      LIDARR_DOMAIN=$(cat ${config.sops.secrets.lidarr_domain.path})
      READARR_DOMAIN=$(cat ${config.sops.secrets.readarr_domain.path})
      BAZARR_DOMAIN=$(cat ${config.sops.secrets.bazarr_domain.path})
      PROWLARR_DOMAIN=$(cat ${config.sops.secrets.prowlarr_domain.path})
      JELLYSEERR_DOMAIN=$(cat ${config.sops.secrets.jellyseerr_domain.path})
      PAPERLESS_DOMAIN=$(cat ${config.sops.secrets.paperless_domain.path})
      MINIFLUX_DOMAIN=$(cat ${config.sops.secrets.miniflux_domain.path})
      CAL_DOMAIN=$(cat ${config.sops.secrets.cal_domain.path})
      HOME_DOMAIN=$(cat ${config.sops.secrets.home_domain.path})
      LINK_DOMAIN=$(cat ${config.sops.secrets.link_domain.path})
      FLARE_DOMAIN=$(cat ${config.sops.secrets.flare_domain.path})
      GRAFANA_DOMAIN=$(cat ${config.sops.secrets.grafana_domain.path})
      KUMA_DOMAIN=$(cat ${config.sops.secrets.kuma_domain.path})
      HASS_DOMAIN=$(cat ${config.sops.secrets.hass_domain.path})
      VAULT_DOMAIN=$(cat ${config.sops.secrets.vault_domain.path})
      AUTH_DOMAIN=$(cat ${config.sops.secrets.auth_domain.path})
      OLLAMA_DOMAIN=$(cat ${config.sops.secrets.ollama_domain.path})

      # Generate cloudflared configuration
      cat > /var/lib/cloudflared/config/config.yml << EOF
      tunnel: $TUNNEL_ID
      credentials-file: ${config.sops.secrets.cloudflare_tunnel_credentials.path}

      ingress:
        # Media Services
        - hostname: $JELLYFIN_DOMAIN
          service: http://$LOCALHOST:${toString config.my.network.ports.jellyfin}
        - hostname: $AUDIOBOOKSHELF_DOMAIN
          service: http://$LOCALHOST:${toString config.my.network.ports.audiobookshelf}
        - hostname: $KAVITA_DOMAIN
          service: http://$LOCALHOST:${toString config.my.network.ports.kavita}
        - hostname: $TDARR_DOMAIN
          service: http://$LOCALHOST:${toString config.my.network.ports.tdarr}
        - hostname: $TRANSMISSION_DOMAIN
          service: http://$HOMESERVER_HOST:${toString config.my.network.ports.transmission}

        # *arr Stack
        - hostname: $SONARR_DOMAIN
          service: http://$LOCALHOST:${toString config.my.network.ports.sonarr}
        - hostname: $RADARR_DOMAIN
          service: http://$LOCALHOST:${toString config.my.network.ports.radarr}
        - hostname: $LIDARR_DOMAIN
          service: http://$LOCALHOST:${toString config.my.network.ports.lidarr}
        - hostname: $READARR_DOMAIN
          service: http://$LOCALHOST:${toString config.my.network.ports.readarr}
        - hostname: $BAZARR_DOMAIN
          service: http://$LOCALHOST:${toString config.my.network.ports.bazarr}
        - hostname: $PROWLARR_DOMAIN
          service: http://$LOCALHOST:${toString config.my.network.ports.prowlarr}
        - hostname: $JELLYSEERR_DOMAIN
          service: http://$LOCALHOST:${toString config.my.network.ports.jellyseerr}

        # Productivity
        - hostname: $PAPERLESS_DOMAIN
          service: http://$LOCALHOST:${toString config.my.network.ports.paperless}
        - hostname: $MINIFLUX_DOMAIN
          service: http://$LOCALHOST:${toString config.my.network.ports.miniflux}
        - hostname: $CAL_DOMAIN
          service: http://$LOCALHOST:${toString config.my.network.ports.radicale}
        - hostname: $HOME_DOMAIN
          service: http://$LOCALHOST:${toString config.my.network.ports.homepage}
        - hostname: $LINK_DOMAIN
          service: http://$LOCALHOST:${toString config.my.network.ports.linkwarden}
        - hostname: $FLARE_DOMAIN
          service: http://$LOCALHOST:${toString config.my.network.ports.flare}

        # Monitoring
        - hostname: $GRAFANA_DOMAIN
          service: http://$LOCALHOST:${toString config.my.network.ports.grafana}
        - hostname: $KUMA_DOMAIN
          service: http://$LOCALHOST:${toString config.my.network.ports.uptime-kuma}

        # Home Automation
        - hostname: $HASS_DOMAIN
          service: http://$LOCALHOST:${toString config.my.network.ports.home-assistant}

        # Security
        - hostname: $VAULT_DOMAIN
          service: http://$LOCALHOST:${toString config.my.network.ports.vaultwarden}
        - hostname: $AUTH_DOMAIN
          service: http://$LOCALHOST:${toString config.my.network.ports.authentik}

        # AI
        - hostname: $OLLAMA_DOMAIN
          service: http://$LOCALHOST:${toString config.my.network.ports.ollama}

        # Default rule
        - service: $DEFAULT_RESPONSE
      EOF

      chown -R cloudflared:cloudflared /var/lib/cloudflared/config
      chmod 600 /var/lib/cloudflared/config/config.yml
    '';
  };

  # Override the cloudflared service to use our generated config
  systemd.services.cloudflared = {
    serviceConfig = {
      ExecStart = pkgs.lib.mkForce "${pkgs.cloudflared}/bin/cloudflared tunnel --config /var/lib/cloudflared/config/config.yml run";
      ExecStartPre = [
        "+${pkgs.coreutils}/bin/mkdir -p /var/lib/cloudflared/config"
      ];
    };
    after = ["cloudflared-config-generator.service"];
    requires = ["cloudflared-config-generator.service"];
  };

  # Remove the original service configuration since we're using a custom approach
  services.cloudflared.enable = false;
}
