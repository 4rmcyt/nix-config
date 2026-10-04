# Caddy + plugins for one host; tags and hashes live in caddy-plugins.json (bumped by `just caddy-update`).
pkgs: host: let
  data = builtins.fromJSON (builtins.readFile ../modules/networking/caddy-plugins.json);
  h = data.hosts.${host};
in
  pkgs.caddy.withPlugins {
    plugins = map (p: "${p}@${data.plugins.${p}}") h.plugins;
    inherit (h) hash;
  }
