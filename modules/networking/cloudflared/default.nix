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

    tunnel_id = {
      sopsFile = ../../../secrets/cloudflared.yaml;
      key = "tunnel_id";
      owner = config.users.users.cloudflared.name;
      group = config.users.groups.cloudflared.name;
    };

    domains = {
      sopsFile = ../../../secrets/cloudflared.yaml;
      key = "domains";
      owner = config.users.users.cloudflared.name;
      group = config.users.groups.cloudflared.name;
      format = "yaml";
    };
  };

  users.users.cloudflared = {
    isSystemUser = true;
    group = "cloudflared";
  };
  users.groups.cloudflared = {};

  systemd.services.cloudflared = {
    after = ["network.target" "network-online.target" "sops-nix.service"];
    wants = ["network.target" "network-online.target"];
    wantedBy = ["multi-user.target"];

    serviceConfig = {
      User = "cloudflared";
      Group = "cloudflared";

      ExecStartPre = let
        configGenerator = pkgs.writeShellScript "generate-cloudflared-config" ''
          set -euo pipefail

          # Read tunnel ID from secrets
          TUNNEL_ID=$(${pkgs.yq-go}/bin/yq -r '.tunnel_id' ${config.sops.secrets.tunnel_id.path})

          # Build config file
          cat > /var/lib/cloudflared/config.yml << EOF
          tunnel: $TUNNEL_ID
          credentials-file: ${config.sops.secrets.cloudflare_tunnel_credentials.path}

          ingress:
          EOF

          # Add each domain as an ingress rule (connect to nginx via HTTPS)
          ${pkgs.yq-go}/bin/yq -o=json '.domains' ${config.sops.secrets.domains.path} \
            | ${pkgs.jq}/bin/jq -r 'to_entries[] | .key' \
            | while read -r domain; do
              cat >> /var/lib/cloudflared/config.yml << INGRESS
            - hostname: $domain
              service: https://localhost:443
              originRequest:
                httpHostHeader: $domain
                noTLSVerify: true
          INGRESS
            done

          # Add default rule (404 for unmatched routes)
          echo "  - service: http_status:404" >> /var/lib/cloudflared/config.yml

          chmod 600 /var/lib/cloudflared/config.yml
        '';
      in [
        "+${pkgs.coreutils}/bin/mkdir -p /var/lib/cloudflared"
        "+${pkgs.coreutils}/bin/chown cloudflared:cloudflared /var/lib/cloudflared"
        "${configGenerator}"
      ];

      ExecStart = "${pkgs.cloudflared}/bin/cloudflared tunnel --config /var/lib/cloudflared/config.yml --no-autoupdate run";
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };
}
