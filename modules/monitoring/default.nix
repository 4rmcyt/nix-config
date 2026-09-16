# Client-side agents (alloy-client.nix, node-exporter-client.nix) live alongside this
# directory but are imported directly by non-homeserver hosts.
{
  imports = [
    ./geoip.nix
    ./alloy-server.nix
    ./grafana.nix
    ./loki.nix
    ./prometheus.nix
    ./alertmanager.nix
  ];
}
