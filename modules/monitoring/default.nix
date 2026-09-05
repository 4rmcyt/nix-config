# Homeserver-side monitoring stack. Split by concern:
#   geoip.nix        — GeoIP MMDB download for Alloy log enrichment
#   alloy-server.nix — Alloy log shipper (Traefik access log + journal -> Loki)
#   grafana.nix       — Grafana (dashboards, OIDC via Kanidm)
#   loki.nix          — Loki log storage + ruler
#   prometheus.nix    — Prometheus + exporters + scrape configs
#   alertmanager.nix  — Alertmanager + ntfy webhook bridge
#
# Client-side agents (alloy-client.nix, node-exporter-client.nix) live
# alongside this directory but are imported directly by non-homeserver hosts.
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
