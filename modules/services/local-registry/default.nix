# Exists to unblock k3s image delivery: side-loading images via `ctr images import`
# hits a reproducible containerd bug ("failed to check if this is a checkpoint image")
# even though crictl lists the image fine — a real registry pull avoids it.
{config, ...}: let
  port = config.my.network.ports.local-registry;
in {
  virtualisation.oci-containers.containers.local-registry = {
    autoStart = true;
    image = "docker.io/library/registry:2";
    extraOptions = [
      "--network=host"
      "--security-opt=no-new-privileges"
      "--cap-drop=all"
    ];
    environment = {
      REGISTRY_HTTP_ADDR = "0.0.0.0:${toString port}";
    };
    volumes = [
      "/var/lib/local-registry:/var/lib/registry"
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

  # LAN only: no auth, so keep it off anything wider than the trusted home LAN.
  networking.firewall.interfaces.enp0s31f6.allowedTCPPorts = [port];
}
