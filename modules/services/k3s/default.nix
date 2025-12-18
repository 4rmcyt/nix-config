{
  config,
  pkgs,
  ...
}: {
  # SOPS Secrets
  sops.secrets = {
    k3s_token_file = {
      sopsFile = ../../../secrets/k3s.yaml;
      key = "tokenFile";
      mode = "0400";
    };
    k3s_keycloak_admin_password = {
      sopsFile = ../../../secrets/k3s.yaml;
      key = "keycloak_admin_password";
      mode = "0400";
    };
  };

  environment.systemPackages = [pkgs.k3s];

  # k3s Service
  systemd.services.k3s = {
    description = "k3s service";
    after = ["network-online.target"];
    wants = ["network-online.target"];
    wantedBy = ["multi-user.target"];

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
      ExecStart = "${pkgs.k3s}/bin/k3s server --token-file=${config.sops.secrets.k3s_token_file.path}";
    };
  };

  # Firewall - NodePort range for external service access
  networking.firewall.allowedTCPPortRanges = [{
    from = 30000;
    to = 32767;
  }];

  # Allow users in wheel group to access kubeconfig
  systemd.tmpfiles.rules = [
    "z /etc/rancher/k3s/k3s.yaml 0640 root wheel -"
  ];
}
