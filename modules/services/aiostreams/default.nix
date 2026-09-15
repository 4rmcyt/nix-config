{config, ...}: {
  sops.secrets.aiostreams_secret_key = {
    sopsFile = ../../../secrets/medialib.yaml;
    key = "aiostreams_secret_key";
    owner = "root";
    mode = "0400";
  };

  sops.templates."aiostreams.env" = {
    owner = "root";
    mode = "0400";
    content = ''
      BASE_URL=https://aiostreams.${config.my.defaults.domain}
      SECRET_KEY=${config.sops.placeholder.aiostreams_secret_key}
      DATABASE_URI=sqlite://./data/db.sqlite
      PORT=${toString config.my.network.ports.aiostreams}
    '';
  };

  virtualisation.oci-containers.containers.aiostreams = {
    autoStart = true;
    image = "ghcr.io/viren070/aiostreams:latest";
    environment = {
      TZ = config.my.defaults.timezone;
    };
    environmentFiles = [config.sops.templates."aiostreams.env".path];
    volumes = ["/var/lib/aiostreams:/app/data"];
    # Host networking (like byparr/comet) -- needs to reach Comet on
    # localhost, no --add-host or extra port publishing needed.
    extraOptions = [
      "--network=host"
      "--label=io.containers.autoupdate=registry"
      "--security-opt=no-new-privileges"
    ];
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/aiostreams 0750 root root -"
  ];
}
