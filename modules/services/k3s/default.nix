{
  config,
  pkgs,
  lib,
  ...
}: let
  manifestDir = "/var/lib/rancher/k3s/server/manifests";
  chartDir = "/var/lib/rancher/k3s/server/static/charts";
  imageDir = "/var/lib/rancher/k3s/agent/images";
  containerdConfigTemplateFile = "/var/lib/rancher/k3s/agent/etc/containerd/config.toml.tmpl";

  # k3s Configuration (single-node setup)
  k3sRole = "server";

  # GitOps configuration
  gitOpsEnabled = true;
  gitOpsRepo = "https://github.com/4rmcyt/gitops.git";
  gitOpsBranch = "main";
  gitOpsPath = "k3s"; # Relative path in repo for k8s manifests
  gitOpsSyncInterval = "5m"; # How often to check for changes

  # Kubelet configuration
  kubeletConfig = {
    apiVersion = "kubelet.config.k8s.io/v1beta1";
    kind = "KubeletConfiguration";
    shutdownGracePeriod = "30s";
    shutdownGracePeriodCriticalPods = "10s";
  };

  # KubeProxy configuration
  kubeProxyConfig = {
    apiVersion = "kubeproxy.config.k8s.io/v1alpha1";
    kind = "KubeProxyConfiguration";
  };

  kubeletConfigFile = (pkgs.formats.yaml {}).generate "k3s-kubelet-config" kubeletConfig;
  kubeProxyConfigFile = (pkgs.formats.yaml {}).generate "k3s-kubeProxy-config" kubeProxyConfig;

  # Note: Keycloak manifest moved to GitOps repo
  # Previously defined keycloakManifest for reference (now in gitops repo at k3s/keycloak/)
  _keycloakManifestExample = [
    # Keycloak Deployment
    {
      apiVersion = "apps/v1";
      kind = "Deployment";
      metadata = {
        name = "keycloak";
        namespace = "default";
        labels.app = "keycloak";
      };
      spec = {
        replicas = 1;
        selector.matchLabels.app = "keycloak";
        strategy = {
          type = "Recreate"; # Avoid multiple instances connecting to DB during upgrade
        };
        template = {
          metadata.labels.app = "keycloak";
          spec = {
            containers = [
              {
                name = "keycloak";
                image = "quay.io/keycloak/keycloak:26.0";
                args = ["start"];
                env = [
                  {
                    name = "KC_DB";
                    value = "postgres";
                  }
                  {
                    name = "KC_DB_URL_HOST";
                    value = config.my.defaults.homeserver_lan;
                  }
                  {
                    name = "KC_DB_URL_PORT";
                    value = "5432";
                  }
                  {
                    name = "KC_DB_URL_DATABASE";
                    value = "keycloak";
                  }
                  {
                    name = "KC_DB_USERNAME";
                    value = "keycloak";
                  }
                  {
                    name = "KC_DB_PASSWORD";
                    valueFrom.secretKeyRef = {
                      name = "keycloak-db-config";
                      key = "db-password";
                    };
                  }
                  {
                    name = "KEYCLOAK_ADMIN";
                    value = "admin";
                  }
                  {
                    name = "KEYCLOAK_ADMIN_PASSWORD";
                    valueFrom.secretKeyRef = {
                      name = "keycloak-admin";
                      key = "password";
                    };
                  }
                  {
                    name = "KC_HOSTNAME";
                    value = "auth.${config.my.defaults.domain}";
                  }
                  {
                    name = "KC_PROXY";
                    value = "edge";
                  }
                  {
                    name = "KC_HTTP_ENABLED";
                    value = "true";
                  }
                  {
                    name = "KC_HEALTH_ENABLED";
                    value = "true";
                  }
                  {
                    name = "KC_METRICS_ENABLED";
                    value = "true";
                  }
                ];
                ports = [
                  {
                    name = "http";
                    containerPort = 8080;
                    protocol = "TCP";
                  }
                ];
                readinessProbe = {
                  httpGet = {
                    path = "/health/ready";
                    port = 8080;
                  };
                  initialDelaySeconds = 60;
                  periodSeconds = 10;
                  timeoutSeconds = 5;
                  failureThreshold = 3;
                };
                livenessProbe = {
                  httpGet = {
                    path = "/health/live";
                    port = 8080;
                  };
                  initialDelaySeconds = 90;
                  periodSeconds = 30;
                  timeoutSeconds = 5;
                  failureThreshold = 3;
                };
                resources = {
                  requests = {
                    memory = "512Mi";
                    cpu = "250m";
                  };
                  limits = {
                    memory = "2Gi";
                    cpu = "1000m";
                  };
                };
              }
            ];
          };
        };
      };
    }
    # Keycloak Service
    {
      apiVersion = "v1";
      kind = "Service";
      metadata = {
        name = "keycloak";
        namespace = "default";
        labels.app = "keycloak";
      };
      spec = {
        type = "LoadBalancer";
        selector.app = "keycloak";
        ports = [
          {
            name = "http";
            port = 9000; # External port (matches cloudflared config)
            targetPort = 8080; # Keycloak container port
            protocol = "TCP";
          }
        ];
      };
    }
  ];

  # Manifests to deploy
  # Note: Keycloak and other app manifests are now managed in the GitOps repository
  # at https://github.com/4rmcyt/gitops.git under k3s/keycloak/
  manifests = {};

  # Generate manifest files with proper YAML formatting
  manifestFiles =
    if manifests == {}
    then pkgs.runCommand "empty-manifests" {} "mkdir -p $out"
    else
      pkgs.linkFarm "k3s-manifests" (
        builtins.map (name: let
          docs = manifests.${name};
          yamlContent =
            if builtins.isList docs
            then
              builtins.concatStringsSep "\n---\n" (
                builtins.map (doc: builtins.readFile ((pkgs.formats.yaml {}).generate "temp" doc)) docs
              )
            else builtins.readFile ((pkgs.formats.yaml {}).generate "temp" docs);
        in {
          name = "${name}.yaml";
          path = pkgs.writeText "${name}.yaml" yamlContent;
        }) (builtins.attrNames manifests)
      );

  # Charts to deploy
  charts = {};

  # Container images to preload
  images = [];

  # Containerd config template
  containerdConfigTemplate = null;

  # Setup script to link manifests, charts, and images
  setupScript = pkgs.writeShellScript "setup-k3s-content" ''
    # Create directories
    ${pkgs.coreutils-full}/bin/mkdir -p ${manifestDir}
    ${pkgs.coreutils-full}/bin/mkdir -p ${chartDir}
    ${pkgs.coreutils-full}/bin/mkdir -p ${imageDir}

    # Link manifests
    ${
      if manifests != {}
      then
        builtins.concatStringsSep "\n    " (
          builtins.map (name:
            "${pkgs.coreutils-full}/bin/ln -sfn ${manifestFiles}/${name}.yaml ${manifestDir}/${name}.yaml")
          (builtins.attrNames manifests)
        )
      else ""
    }

    # Link charts
    ${builtins.concatStringsSep "\n    " (
      lib.mapAttrsToList (name: path: let
        target =
          if lib.hasSuffix ".tgz" name
          then name
          else "${name}.tgz";
      in "${pkgs.coreutils-full}/bin/ln -sfn ${path} ${chartDir}/${target}")
      charts
    )}

    # Link images
    ${builtins.concatStringsSep "\n    " (
      builtins.map (image:
        "${pkgs.coreutils-full}/bin/ln -sfn ${image} ${imageDir}/${image.name}")
      images
    )}

    # Setup containerd config template if provided
    ${lib.optionalString (containerdConfigTemplate != null) ''
      mkdir -p $(dirname ${containerdConfigTemplateFile})
      ${pkgs.coreutils-full}/bin/ln -sfn ${pkgs.writeText "config.toml.tmpl" containerdConfigTemplate} ${containerdConfigTemplateFile}
    ''}
  '';
in {
  # =================================================================
  # SOPS Secrets for k3s and Keycloak
  # =================================================================
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

  # Note: keycloak_db_password is already defined in modules/database/postgresql/default.nix

  environment.systemPackages = [pkgs.k3s];

  # =================================================================
  # k3s Service
  # =================================================================
  systemd.services.k3s = {
    description = "k3s service";
    after = [
      "firewall.service"
      "network-online.target"
      "postgresql.service" # Wait for system PostgreSQL
    ];
    wants = [
      "firewall.service"
      "network-online.target"
    ];
    requires = ["postgresql.service"];
    wantedBy = ["multi-user.target"];
    path = lib.optional config.boot.zfs.enabled config.boot.zfs.package;

    serviceConfig = {
      Type = if k3sRole == "agent" then "exec" else "notify";
      KillMode = "process";
      Delegate = "yes";
      Restart = "always";
      RestartSec = "5s";
      LimitNOFILE = 1048576;
      LimitNPROC = "infinity";
      LimitCORE = "infinity";
      TasksMax = "infinity";
      ExecStartPre = setupScript;
      ExecStart = lib.concatStringsSep " \\\n  " (
        [
          "${pkgs.k3s}/bin/k3s ${k3sRole}"
          "--kubelet-arg=config=${kubeletConfigFile}"
          "--kube-proxy-arg=config=${kubeProxyConfigFile}"
        ]
      );
    };
  };

  # =================================================================
  # Post-deployment: Create k8s secrets from sops
  # =================================================================
  systemd.services.k3s-setup-secrets = {
    description = "Setup k3s secrets from sops";
    after = ["k3s.service" "sops-nix.service"];
    requires = ["k3s.service"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      # Wait for k3s to be ready
      until ${pkgs.k3s}/bin/kubectl get nodes &>/dev/null; do
        echo "Waiting for k3s to be ready..."
        sleep 5
      done

      # Create keycloak-db-config secret with db-password from sops
      if ! ${pkgs.k3s}/bin/kubectl get secret keycloak-db-config -n default &>/dev/null; then
        ${pkgs.k3s}/bin/kubectl create secret generic keycloak-db-config \
          --from-literal=db-password="$(cat ${config.sops.secrets.keycloak_db_password.path})" \
          -n default
      else
        # Update existing secret
        ${pkgs.k3s}/bin/kubectl create secret generic keycloak-db-config \
          --from-literal=db-password="$(cat ${config.sops.secrets.keycloak_db_password.path})" \
          -n default \
          --dry-run=client -o yaml | ${pkgs.k3s}/bin/kubectl apply -f -
      fi

      # Create keycloak-admin secret
      if ! ${pkgs.k3s}/bin/kubectl get secret keycloak-admin -n default &>/dev/null; then
        ${pkgs.k3s}/bin/kubectl create secret generic keycloak-admin \
          --from-literal=username=admin \
          --from-literal=password="$(cat ${config.sops.secrets.k3s_keycloak_admin_password.path})" \
          -n default
      else
        # Update existing secret
        ${pkgs.k3s}/bin/kubectl create secret generic keycloak-admin \
          --from-literal=username=admin \
          --from-literal=password="$(cat ${config.sops.secrets.k3s_keycloak_admin_password.path})" \
          -n default \
          --dry-run=client -o yaml | ${pkgs.k3s}/bin/kubectl apply -f -
      fi

      echo "k3s secrets setup complete"
    '';
  };

  # =================================================================
  # GitOps: Auto-deploy from git repository
  # =================================================================
  systemd.services.k3s-gitops-sync = lib.mkIf gitOpsEnabled {
    description = "k3s GitOps sync from ${gitOpsRepo}";
    after = ["k3s.service" "network-online.target"];
    requires = ["k3s.service"];
    wantedBy = ["multi-user.target"];

    serviceConfig = {
      Type = "oneshot";
      WorkingDirectory = "/var/lib/k3s-gitops";
      StateDirectory = "k3s-gitops";
    };

    script = ''
      # Ensure git is available
      export PATH="${pkgs.git}/bin:${pkgs.k3s}/bin:$PATH"

      # Wait for k3s to be ready
      until kubectl get nodes &>/dev/null; do
        echo "Waiting for k3s to be ready..."
        sleep 5
      done

      # Clone or update repository
      if [ ! -d ".git" ]; then
        echo "Cloning repository ${gitOpsRepo}..."
        git clone -b ${gitOpsBranch} ${gitOpsRepo} .
      else
        echo "Updating repository..."
        git fetch origin ${gitOpsBranch}

        # Check if there are any changes
        LOCAL=$(git rev-parse HEAD)
        REMOTE=$(git rev-parse origin/${gitOpsBranch})

        if [ "$LOCAL" = "$REMOTE" ]; then
          echo "No changes detected, skipping deployment"
          exit 0
        fi

        echo "Changes detected: $LOCAL -> $REMOTE"
        git reset --hard origin/${gitOpsBranch}
      fi

      # Apply manifests if directory exists
      if [ -d "${gitOpsPath}" ]; then
        echo "Applying manifests from ${gitOpsPath}..."
        kubectl apply -f ${gitOpsPath}/ --recursive
      else
        echo "Warning: ${gitOpsPath} not found in repository"
      fi

      echo "GitOps sync complete"
    '';
  };

  systemd.timers.k3s-gitops-sync = lib.mkIf gitOpsEnabled {
    description = "Timer for k3s GitOps sync";
    wantedBy = ["timers.target"];
    timerConfig = {
      OnBootSec = "2min"; # Run 2 minutes after boot
      OnUnitActiveSec = gitOpsSyncInterval;
      Unit = "k3s-gitops-sync.service";
    };
  };

  # =================================================================
  # Firewall Configuration
  # =================================================================
  # Port Analysis - NO CONFLICTS DETECTED:
  #
  # k3s ports:
  # - 6443: Kubernetes API server
  # - 8472: Flannel VXLAN (UDP)
  # - 9000: Keycloak via LoadBalancer (already used by system keycloak)
  # - 10250: Kubelet metrics
  # - 30000-32767: NodePort range
  #
  # Existing service ports:
  # - 587: SMTP, 1883: MQTT, 3001: Kuma, 3003: Grafana
  # - 3493: NUT, 5000: Kavita, 5232: Radicale, 5432: PostgreSQL
  # - 6767: Bazarr, 7878: Radarr, 8069: Microbin
  # - 8082: Homepage, 8086: Miniflux, 8096: Jellyfin
  # - 8123: Hass, 8686: Lidarr, 8787: Readarr, 8881: Atuin
  # - 8888: Paperless, 8989: Sonarr, 9292: Audiobookshelf
  # - 9696: Prowlarr, 11434: Ollama

  networking.firewall = {
    allowedTCPPorts = [
      6443 # Kubernetes API server
      10250 # Kubelet metrics
      # Port 9000 already opened by modules/security/keycloak/default.nix
    ];
    allowedUDPPorts = [
      8472 # Flannel VXLAN
    ];
    # Allow NodePort range for k3s services
    allowedTCPPortRanges = [
      {
        from = 30000;
        to = 32767;
      }
    ];
  };

  # =================================================================
  # System Directories
  # =================================================================
  systemd.tmpfiles.rules = [
    "d /var/lib/rancher 0755 root root -"
    "d /var/lib/rancher/k3s 0755 root root -"
    "d /var/lib/rancher/k3s/server 0755 root root -"
    "d /var/lib/rancher/k3s/agent 0755 root root -"
    "d /var/lib/k3s-gitops 0755 root root -"
  ];
}
