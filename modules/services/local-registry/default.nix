# Minimal, unauthenticated local Docker registry — homeserver-only, exists
# purely to unblock k3s image delivery: `ctr images import`/k3s's
# agent/images/ side-load path hits a reproducible containerd bug where
# kubelet's checkpoint-image check fails to resolve a locally side-loaded
# image ("failed to check if this is a checkpoint image ... not found") even
# though crictl images lists it fine. A real registry pull goes through
# containerd's normal code path instead and doesn't hit this.
#
# --network=host: the registry needs to be reachable at 127.0.0.1:5000 from
# k3s's own containerd (a host process, not a pod) with zero extra
# firewall/CNI plumbing — same reasoning as komf's --network=host.
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

  # Plain HTTP, no auth — k3s's containerd needs to be told explicitly not
  # to expect TLS for this host, otherwise it defaults to https and refuses.
  environment.etc."rancher/k3s/registries.yaml".text = ''
    mirrors:
      "localhost:${toString port}":
        endpoint:
          - "http://localhost:${toString port}"
  '';

  # LAN only (enp0s31f6) — lets a dev machine on the same network `podman
  # push` a freshly built image; not exposed on tailscale0/cni0, no auth so
  # keep it off anything wider than the trusted home LAN.
  networking.firewall.interfaces.enp0s31f6.allowedTCPPorts = [port];
}
