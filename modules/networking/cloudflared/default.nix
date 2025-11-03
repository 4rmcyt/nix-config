{
  config,
  pkgs,
  lib,
  ...
}: {
  sops.secrets = {
    # Cloudflare tunnel credentials (binary file)
    cloudflare_tunnel_credentials = {
      sopsFile = ../../../secrets/cloudflare_tunnel_credentials.bin;
      key = "credentials";
      owner = "cloudflared";
      group = "cloudflared";
      mode = "0400";
      format = "binary";
    };

    # Cloudflare configuration (tunnel ID, domains, default response)
    cloudflared = {
      sopsFile = ../../../secrets/cloudflared.yaml;
      key = "cloudflared";
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
          TUNNEL_ID=$(${pkgs.yq-go}/bin/yq -r '.tunnel_id' ${config.sops.secrets.cloudflared.path})

          # Build config file
          cat > /var/lib/cloudflared/config.yml << EOF
          tunnel: $TUNNEL_ID
          credentials-file: ${config.sops.secrets.cloudflare_tunnel_credentials.path}

          ingress:
          EOF

          # Add each domain as an ingress rule (connect to nginx via HTTPS)
          ${pkgs.yq-go}/bin/yq -o=json '.domains' ${config.sops.secrets.cloudflared.path} | \
            ${pkgs.jq}/bin/jq -r 'to_entries[] | "  - hostname: \(.key)\n    service: https://localhost:443\n    originRequest:\n      httpHostHeader: \(.key)\n      noTLSVerify: true"' \
            >> /var/lib/cloudflared/config.yml

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
