# modules/services/komf/default.nix
{
  config,
  ...
}:
{
  sops.secrets.kavita_api_key = {
    sopsFile = ../../../secrets/medialib.yaml;
    key = "kavita_api_key";
    owner = "root";
    mode = "0400";
  };

  # sops.templates."komf-application.yml" = {
  #   owner = "root";
  #   mode = "0444";
  #   content = ''
  #     kavita:
  #       baseUri: "http://localhost:5000"
  #       apiKey: "${config.sops.placeholder.kavita_api_key}"

  #     database:
  #       file: /config/database.sqlite

  #     server:
  #       port: 8085

  #     logLevel: INFO
  #   '';
  # };

  virtualisation.oci-containers.containers.komf = {
    autoStart = true;
    image = "sndxr/komf:latest";
    extraOptions = [
      "--network=host"
      "--env=JAVA_TOOL_OPTIONS=-XX:+UnlockExperimentalVMOptions -XX:+UseShenandoahGC -XX:ShenandoahGCHeuristics=compact -XX:ShenandoahGuaranteedGCInterval=3600000 -XX:TrimNativeHeapInterval=3600000"
      "--secret=${config.sops.secrets.kavita_api_key.path},type=mount,target=/run/secrets/kavita_api_key"
    ];
    environment = {
      KOMF_KAVITA_BASE_URI = "http://localhost:5000";
    };
    volumes = [
      "/var/lib/komf:/config"
    ];
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/komf 0750 root root -"
  ];
}
