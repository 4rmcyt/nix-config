# Shared shape for the Cloudflare DNS-01 ACME credentials secret, owned by
# whichever reverse proxy (traefik or caddy) is enabled on a given host.
owner: {
  sopsFile = ../secrets/cloudflare_acme_credentials.env;
  inherit owner;
  group = owner;
  mode = "0400";
  format = "dotenv";
  # Proxies read it as EnvironmentFile at start only; owner doubles as the unit name.
  restartUnits = ["${owner}.service"];
}
