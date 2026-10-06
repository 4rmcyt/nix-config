{
  config,
  pkgs,
  ...
}: {
  sops.secrets = {
    k3s_token_file = {
      sopsFile = ../../../secrets/k3s.yaml;
      key = "tokenFile";
      mode = "0400";
    };
  };

  environment.systemPackages = [pkgs.k3s];

  systemd.services.k3s = {
    description = "k3s service";
    after = ["network-online.target"];
    wants = ["network-online.target"];
    wantedBy = ["multi-user.target"];
    path = [config.boot.zfs.package];

    serviceConfig = {
      Type = "notify";
      KillMode = "process";
      Delegate = "yes";
      Restart = "always";
      RestartSec = "5s";
      LimitNOFILE = 1048576;
      LimitNPROC = "infinity";
      LimitCORE = "infinity";
      TasksMax = "infinity";
      # NodePorts loopback-only (iptables proxier): Caddy reaches them on localhost, nothing else on the LAN can.
      ExecStart = ''
        ${pkgs.k3s}/bin/k3s server \
          --token-file=${config.sops.secrets.k3s_token_file.path} \
          --disable=traefik \
          --disable=servicelb \
          --kube-controller-manager-arg=terminated-pod-gc-threshold=50 \
          --kube-proxy-arg=nodeport-addresses=127.0.0.0/8 \
          --write-kubeconfig-mode=0640
      '';
    };
  };

  systemd.tmpfiles.rules = [
    "z /etc/rancher/k3s/k3s.yaml 0640 root wheel -"
  ];
}
