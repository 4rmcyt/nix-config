# modules/services/komf/default.nix
{
  config,
  lib,
  ...
}:
let
  inherit (config.my.defaults) domain;
in
{
  sops.secrets.kavita_api_key = {
    sopsFile = ../../../secrets/medialib.yaml;
    key = "kavita_api_key";
    owner = "root";
    mode = "0400";
  };

  # komf reads /run/secrets/kavita_api_key at startup via env file
  sops.templates."komf-env" = {
    owner = "root";
    mode = "0400";
    content = ''
      KOMF_KAVITA_BASE_URI=http://localhost:5000
      KOMF_KAVITA_API_KEY=${config.sops.placeholder.kavita_api_key}
      KOMF_LOG_LEVEL=INFO
      JAVA_TOOL_OPTIONS=-XX:+UnlockExperimentalVMOptions -XX:+UseShenandoahGC -XX:ShenandoahGCHeuristics=compact -XX:ShenandoahGuaranteedGCInterval=3600000 -XX:TrimNativeHeapInterval=3600000
    '';
  };

  virtualisation.oci-containers.containers.komf = {
    autoStart = true;
    image = "sndxr/komf:latest";
    extraOptions = [
      "--network=host"
      "--env-file=${config.sops.templates."komf-env".path}"
    ];
    volumes = [
      "/var/lib/komf:/config"
    ];
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/komf 0750 root root -"
  ];
}
