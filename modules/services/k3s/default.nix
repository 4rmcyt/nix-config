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

  # GitOps sync
  systemd.services.k3s-gitops-sync = {
    description = "k3s GitOps sync";
    after = ["k3s.service"];
    wants = ["k3s.service"];

    serviceConfig = {
      Type = "oneshot";
      WorkingDirectory = "/var/lib/k3s-gitops";
      StateDirectory = "k3s-gitops";
    };

    script = ''
      export PATH="${pkgs.git}/bin:${pkgs.k3s}/bin:$PATH"
      export KUBECONFIG="/etc/rancher/k3s/k3s.yaml"

      # Wait up to 60 seconds for k3s to be ready
      for i in {1..12}; do
        if kubectl get nodes &>/dev/null; then
          break
        fi
        if [ $i -eq 12 ]; then
          echo "k3s not ready after 60 seconds, skipping GitOps sync"
          exit 0
        fi
        sleep 5
      done

      # Initialize or update git repository
      if [ ! -d ".git" ]; then
        # Remove any non-git files and clone fresh
        rm -rf * .[!.]* 2>/dev/null || true
        git clone -b main https://github.com/4rmcyt/gitops.git .
      else
        git fetch origin main
        LOCAL=$(git rev-parse HEAD)
        REMOTE=$(git rev-parse origin/main)
        [ "$LOCAL" = "$REMOTE" ] && exit 0
        git reset --hard origin/main
      fi

      [ -d "k3s" ] && kubectl apply -f k3s/ --recursive
    '';
  };

  systemd.timers.k3s-gitops-sync = {
    description = "Timer for k3s GitOps sync";
    wantedBy = ["timers.target"];
    timerConfig = {
      OnBootSec = "2min";
      OnUnitActiveSec = "5m";
      Unit = "k3s-gitops-sync.service";
    };
  };

  # Firewall - NodePort range for external service access
  networking.firewall.allowedTCPPortRanges = [{
    from = 30000;
    to = 32767;
  }];

  # Directories
  systemd.tmpfiles.rules = [
    "d /var/lib/k3s-gitops 0755 root root -"
  ];
}
