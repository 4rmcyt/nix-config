# Exists to unblock k3s image delivery: side-loading images via `ctr images import`
# hits a reproducible containerd bug ("failed to check if this is a checkpoint image")
# even though crictl lists the image fine — a real registry pull avoids it.
{config, ...}: let
  port = config.my.network.ports.local-registry;
in {
  virtualisation.oci-containers.containers.local-registry = {
    autoStart = true;
    image = "docker.io/library/registry:2";
    # Published ports are DNAT'd past the NixOS firewall: bind loopback only (k3s pulls via localhost:5000, registries.yaml).
    ports = [
      "127.0.0.1:${toString port}:${toString port}"
    ];
    extraOptions = [
      # Container root maps to an unprivileged subuid; idmap keeps host-side ownership root:root.
      "--userns=auto"
      "--security-opt=no-new-privileges"
      "--cap-drop=all"
    ];
    environment = {
      REGISTRY_HTTP_ADDR = "0.0.0.0:${toString port}";
    };
    volumes = [
      "/var/lib/local-registry:/var/lib/registry:idmap"
    ];
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/local-registry 0750 root root -"
  ];

  # k3s's containerd needs to be told explicitly not to expect TLS, otherwise it
  # defaults to https and refuses.
  environment.etc."rancher/k3s/registries.yaml".text = ''
    mirrors:
      "localhost:${toString port}":
        endpoint:
          - "http://localhost:${toString port}"
  '';
}
