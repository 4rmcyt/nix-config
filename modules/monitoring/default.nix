# homeserver's monitoring stack; journal-upload and node-exporter are the per-host clients other hosts import directly.
{
  imports = [
    ./alertmanager
    ./geoip
    ./grafana
    ./journal-upload
    ./prometheus
    ./victorialogs
  ];
}
