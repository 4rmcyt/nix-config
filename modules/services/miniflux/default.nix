{
  config,
  lib,
  pkgs,
  ...
}: let
  customCss = pkgs.writeText "miniflux-mocha.css" ''
    /* Catppuccin Mocha */
    :root {
      --rosewater: #f5e0dc;
      --flamingo: #f2cdcd;
      --pink: #f5c2e7;
      --mauve: #cba6f7;
      --red: #f38ba8;
      --maroon: #eba0ac;
      --peach: #fab387;
      --yellow: #f9e2af;
      --green: #a6e3a1;
      --teal: #94e2d5;
      --sky: #89dceb;
      --sapphire: #74c7ec;
      --blue: #89b4fa;
      --lavender: #b4befe;
      --text: #cdd6f4;
      --subtext1: #bac2de;
      --subtext0: #a6adc8;
      --overlay2: #9399b2;
      --overlay1: #7f849c;
      --overlay0: #6c7086;
      --surface2: #585b70;
      --surface1: #45475a;
      --surface0: #313244;
      --base: #1e1e2e;
      --mantle: #181825;
      --crust: #11111b;
    }

    :root {
      --item-status-read-title-link-color: var(--link-color);
      --body-color: var(--text);
      --body-background: var(--base);
      --hr-border-color: var(--overlay1);
      --title-color: var(--text);
      --link-color: var(--blue);
      --link-focus-color: var(--surface1);
      --link-hover-color: var(--lavender);
      --link-visited-color: var(--mauve);
      --header-list-border-color: var(--overlay1);
      --header-link-color: var(--blue);
      --header-link-focus-color: var(--key);
      --header-link-hover-color: var(--lavender);
      --header-active-link-color: var(--overlay1);
      --table-border-color: var(--overlay1);
      --table-th-background: var(--surface0);
      --table-th-color: var(--overlay0);
      --table-tr-hover-background-color: var(--base);
      --table-tr-hover-color: var(--overlay0);
      --button-primary-border-color: var(--overlay0);
      --button-primary-background: var(--overlay0);
      --button-primary-color: var(--base);
      --button-primary-focus-border-color: var(--overlay1);
      --button-primary-focus-background: var(--overlay1);
      --input-background: var(--surface0);
      --input-color: var(--text);
      --input-placeholder-color: var(--subtext1);
      --input-focus-color: var(--text);
      --input-focus-border-color: var(--surface1);
      --input-border: var(--surface1);
      --input-focus-box-shadow: 0 0 0 2px var(--overlay1);
      --alert-color: var(--yellow);
      --alert-confirm-color: var(--red);
      --alert-background-color: var(--base);
      --alert-border-color: var(--overlay1);
      --alert-success-color: var(--green);
      --alert-success-background-color: var(--surface0);
      --alert-success-border-color: var(--overlay1);
      --alert-error-color: var(--red);
      --alert-error-background-color: var(--red);
      --alert-error-border-color: var(--red);
      --alert-info-color: var(--overlay0);
      --alert-info-background-color: var(--surface0);
      --alert-info-border-color: var(--surface0);
      --page-header-title-border-color: var(--overlay1);
      --page-header-title-color: var(--text);
      --logo-color: var(--text);
      --logo-hover-color-span: var(--blue);
      --panel-background: var(--base);
      --panel-border-color: var(--overlay1);
      --panel-color: var(--text);
      --modal-background: var(--base);
      --modal-color: var(--overlay0);
      --modal-box-shadow: 2px 0 5px 0 var(--overlay1);
      --pagination-link-color: var(--blue);
      --pagination-border-color: var(--overlay1);
      --category-color: var(--text);
      --category-background-color: var(--surface0);
      --category-border-color: var(--overlay1);
      --category-link-color: var(--blue);
      --category-link-hover-color: var(--lavender);
      --item-header-color: var(--text);
      --item-border-color: var(--overlay1);
      --item-status-unread-title-link-color: var(--blue);
      --item-status-read-title-link-color: var(--mauve);
      --item-status-read-title-focus-color: var(--overlay1);
      --item-meta-focus-color: var(--text);
      --item-meta-icons-external-url: var(--subtext0);
      --item-meta-li-color: var(--subtext0);
      --item-meta-icons-star: var(--subtext0);
      --current-item-border-color: var(--surface0);
      --entry-header-border-color: var(--overlay1);
      --entry-header-title-link-color: var(--text);
      --entry-meta-color: var(--mauve);
      --entry-author-color: var(--green);
      --entry-content-color: var(--text);
      --entry-content-code-color: var(--blue);
      --entry-content-code-background: var(--base);
      --entry-content-code-border-color: var(--overlay1);
      --entry-content-fig-caption: var(--subtext0);
      --entry-content-quote-color: var(--mauve);
      --entry-content-abbr-border-color: var(--overlay1);
      --entry-enclosure-border-color: var(--overlay1);
      --parsing-error-color: var(--overlay1);
      --feed-parsing-error-background-color: var(--surface0);
      --feed-parsing-error-border-color: var(--red);
      --feed-has-unread-background-color: var(--surface0);
      --feed-has-unread-border-color: var(--text);
      --category-has-unread-background-color: var(--surface0);
      --category-has-unread-border-color: var(--sky);
      --keyboard-shortcuts-li-color: var(--overlay0);
      --counter-color: var(--overlay0);
    }

    .logo a span { color: var(--green); }
    .entry-meta > span > a { color: var(--entry-meta-color); }
    .entry-date { color: var(--entry-meta-color); }
    .item-meta > ul > li { color: var(--item-meta-li-color); }
    .item-meta > ul > li > a { color: var(--item-meta-li-color); }
    .item-meta > ul > li > a:hover { color: var(--item-meta-focus-color); }
    .item-meta-icons li > :is(a, button) { color: var(--item-meta-li-color); }
    .item-meta-icons li > :is(a, button):hover { color: var(--item-meta-focus-color); }
    .entry-author { color: var(--entry-author-color); }
    .entry-content figcaption { color: var(--entry-content-fig-caption); }

    input[type="search"],
    input[type="url"],
    input[type="password"],
    input[type="text"],
    input[type="number"],
    select,
    textarea {
      color: var(--input-color);
      background: var(--input-background);
      border: var(--input-border);
    }

    label input[type="checkbox"] { accent-color: var(--button-primary); }

    /* ── QoL tweaks ── */

    @import url('https://fonts.googleapis.com/css2?family=Literata:ital,opsz,wght@0,7..72,300;0,7..72,400;1,7..72,300;1,7..72,400&display=swap');

    body { max-width: 860px; }

    .entry-content {
      font-family: 'Literata', Georgia, 'Times New Roman', serif;
      font-size: 1.05rem;
      line-height: 1.8;
    }

    /* Sticky top nav */
    .header {
      position: sticky;
      top: 0;
      z-index: 2;
      background-color: var(--body-background);
      padding-bottom: 0.25rem;
    }

    /* Hide comment counts (noise) */
    .item-meta-icons-comments { display: none; }

    /* Soften item borders */
    .item { border-bottom: 1px solid var(--surface1); }

    /* Mobile: fixed prev/next so you never scroll to navigate */
    @media screen and (max-width: 480px) {
      body { margin-left: 8px; margin-right: 8px; }
      .pagination-entry-bottom {
        position: fixed;
        bottom: 0;
        left: 0;
        right: 0;
        background: var(--body-background);
        padding: 8px 12px;
        z-index: 10;
        border-top: 1px solid var(--surface1);
      }
    }
  '';
in {
  sops.secrets = {
    miniflux_db_password = {
      sopsFile = ../../../secrets/postgresql.yaml;
      key = "miniflux_db_password";
      owner = config.users.users.postgres.name;
      group = config.users.groups.postgres.name;
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
    miniflux_oidc_client_secret = {
      sopsFile = ../../../secrets/kanidm.yaml;
      key = "kanidm_miniflux_secret";
      owner = config.users.users.miniflux.name;
      group = config.users.groups.miniflux.name;
      mode = "0400";
    };
  };

  users.users.miniflux = {
    isSystemUser = true;
    group = "miniflux";
    extraGroups = ["users"];
  };
  users.groups.miniflux = {};

  networking.firewall.allowedTCPPorts = [
    config.my.network.ports.miniflux
  ];

  environment.systemPackages = [pkgs.miniflux];
  services.miniflux = {
    enable = true;
    adminCredentialsFile = config.sops.secrets.miniflux_admin_creds.path;
    config = {
      WORKER_POOL_SIZE = "5";
      POLLING_FREQUENCY = "60";
      BATCH_SIZE = "100";
      CREATE_ADMIN = 1;
      CLEANUP_ARCHIVE_READ_DAYS = "60";
      BASE_URL = "https://miniflux.${config.my.defaults.domain}";
      LISTEN_ADDR = "localhost:${toString config.my.network.ports.miniflux}";
      DATABASE_MIGRATIONS = 1;
      DATABASE_URL = lib.mkForce "user=miniflux password=${config.sops.secrets.miniflux_db_password.path} dbname=miniflux sslmode=disable host=/run/postgresql";

      OAUTH2_PROVIDER = "oidc";
      OAUTH2_CLIENT_ID = "miniflux";
      OAUTH2_CLIENT_SECRET_FILE = config.sops.secrets.miniflux_oidc_client_secret.path;
      OAUTH2_REDIRECT_URL = "https://miniflux.${config.my.defaults.domain}/oauth2/oidc/callback";
      OAUTH2_OIDC_DISCOVERY_ENDPOINT = "https://idm.${config.my.defaults.domain}/oauth2/openid/miniflux";
      OAUTH2_USER_CREATION = "1";
    };
  };

  # Apply Catppuccin Mocha theme + QoL CSS to all users via API
  systemd.services.miniflux-theme = {
    description = "Apply Miniflux Catppuccin Mocha theme";
    after = ["miniflux.service"];
    requires = ["miniflux.service"];
    wantedBy = ["multi-user.target"];
    path = [pkgs.curl pkgs.jq];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      EnvironmentFile = config.sops.secrets.miniflux_admin_creds.path;
    };
    script = ''
      url="http://localhost:${toString config.my.network.ports.miniflux}"

      until curl -sf "$url/healthcheck" > /dev/null; do
        sleep 2
      done

      payload=$(jq -n --arg css "$(cat ${customCss})" \
        '{"theme": "dark_serif", "extra_css": $css}')

      curl -sf -u "$ADMIN_USERNAME:$ADMIN_PASSWORD" "$url/v1/users" \
        | jq -r '.[].id' \
        | while read -r uid; do
            curl -sf -X PUT \
              -u "$ADMIN_USERNAME:$ADMIN_PASSWORD" \
              -H "Content-Type: application/json" \
              -d "$payload" \
              "$url/v1/users/$uid"
          done
    '';
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/miniflux 0755 miniflux miniflux -"
    "d /var/lib/miniflux/cache 0755 miniflux miniflux -"
    "d /var/lib/miniflux/logs 0755 miniflux miniflux -"
    "d /var/lib/miniflux/data 0755 miniflux miniflux -"
  ];
}
