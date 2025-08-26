{ pkgs }:

let
  homeserver = import ../hosts/nixos/homeserver {
    # Mock inputs if needed, for example:
    # config = { my.security.ssl.certPath = "/var/lib/acme/example.com/fullchain.pem"; };
  };
in
pkgs.nixosTest {
  name = "homeserver-comprehensive-tests";
  nodes.machine = { pkgs, ... }: {
    imports = homeserver.modules;
    # Add host entries to simulate DNS resolution inside the VM
    networking.extraHosts = ''
      127.0.0.1 jellyfin.example.com
      127.0.0.1 paperless.example.com
      127.0.0.1 hass.example.com
      127.0.0.1 auth.example.com
      127.0.0.1 home.example.com
    '';
  };

  testScript = ''
    start_all();

    # --- 🌐 Networking and Service Availability Tests ---
    machine.wait_for_unit("network-online.target");
    machine.wait_for_open_port(22);
    machine.wait_for_open_port(80);
    machine.wait_for_open_port(443);
    machine.wait_for_open_port(9090); # Prometheus
    machine.wait_for_open_port(3000); # Grafana
    machine.wait_for_open_port(8123); # Home Assistant
    machine.wait_for_open_port(139);  # Samba
    machine.wait_for_open_port(445);  # Samba

    # Test Nginx reverse proxy and service health
    machine.succeed("curl --fail http://localhost/ | grep 'Welcome to nginx!'");
    machine.succeed("curl --fail http://home.example.com | grep 'Homepage'");
    machine.succeed("curl --fail http://paperless.example.com | grep 'Paperless-ngx'");
    machine.succeed("curl --fail http://hass.example.com | grep 'Home Assistant'");
    machine.succeed("curl --fail http://localhost:9090 | grep 'Prometheus'");

    # --- 🚀 Service Status Tests ---
    machine.wait_for_unit("sshd.service");
    machine.wait_for_unit("nginx.service");
    machine.wait_for_unit("smbd.service");
    machine.wait_for_unit("jellyfin.service");
    machine.wait_for_unit("sonarr.service");
    machine.wait_for_unit("radarr.service");
    machine.wait_for_unit("home-assistant.service");
    machine.wait_for_unit("prometheus.service");
    machine.wait_for_unit("grafana.service");
    machine.wait_for_unit("uptime-kuma.service");
    machine.wait_for_unit("paperless.service");
    machine.wait_for_unit("miniflux.service");
    machine.wait_for_unit("radicale.service");
    machine.wait_for_unit("vaultwarden.service");
    machine.wait_for_unit("tailscaled.service");

    # --- 🗄️ Database and Filesystem Tests ---
    machine.wait_for_unit("postgresql.service");
    machine.succeed('sudo -u postgres psql -c "\\l" | grep -q "miniflux"');
    machine.succeed('sudo -u postgres psql -c "\\l" | grep -q "paperless"');
    machine.succeed('sudo -u postgres psql -c "\\l" | grep -q "hass"');
    machine.succeed("zpool status zroot | grep -q 'state: ONLINE'");
    machine.succeed("df -h /nix | grep -q 'zroot/nix'");
    machine.succeed("df -h /home | grep -q 'zroot/home'");
    machine.succeed("df -h /var/log | grep -q 'zroot/log'");

    # --- 💂 User and Security Tests ---
    machine.succeed("id zeev | grep -q 'wheel'");
    machine.succeed("getent group media");
    machine.succeed("stat -c '%a' /var/lib/sops/age.key | grep -q '600'");
    machine.succeed("stat -c '%U:%G' /var/lib/sops/age.key | grep -q 'root:root'");
    machine.succeed("[ -s /run/secrets/cloudflare_acme_credentials ]"); # Check that sops decrypted file is not empty

    # --- 🔒 Fail2ban Tests ---
    machine.wait_for_unit("fail2ban.service");
    machine.succeed("fail2ban-client status | grep 'Action \\|.*cloudflare-token'");
    machine.succeed("fail2ban-client status sshd | grep 'Status \\|.*true'");

    # --- 📦 Container Tests ---
    machine.wait_for_unit("podman.service");
    machine.succeed("podman ps --format '{{.Status}}' --filter name=lazylibrarian | grep -q 'Up'");
    machine.succeed("podman ps --format '{{.Status}}' --filter name=flaresolverr | grep -q 'Up'");

    # --- 💾 Backup Tests ---
    machine.wait_for_unit("borgmatic.service");
    machine.succeed("cat /etc/borgmatic/config.yaml | grep -q '/var/lib/home-assistant'");
    machine.succeed("cat /etc/borgmatic/config.yaml | grep -q '/var/lib/paperless'");
    machine.succeed("cat /etc/borgmatic/config.yaml | grep -q '/etc'");
  '';
}