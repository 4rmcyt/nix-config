{
  config,
  pkgs,
  ...
}: let
  argocdVersion = "v3.5.2";
  argocdManifest = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/argoproj/argo-cd/${argocdVersion}/manifests/install.yaml";
    hash = "sha256-mofys+FMJ48SUB6w71w5VbJ88FNwykJTgcapCM+FpcU=";
  };
in {
  # PAT for cloning the private 4rmcyt/gitops repo over HTTPS.
  sops.secrets.git_access_token = {
    sopsFile = ../../../secrets/common.yaml;
    key = "git_access_token";
    mode = "0400";
  };

  # ArgoCD repository credential secret, rendered from sops (never committed).
  sops.templates."argocd-gitops-repo.yaml" = {
    owner = "root";
    mode = "0400";
    content = ''
      apiVersion: v1
      kind: Secret
      metadata:
        name: gitops-repo
        namespace: argocd
        labels:
          argocd.argoproj.io/secret-type: repository
      stringData:
        type: git
        url: https://github.com/4rmcyt/gitops.git
        username: 4rmcyt
        password: ${config.sops.placeholder.git_access_token}
    '';
  };

  systemd.services.argocd-install = {
    description = "Install ArgoCD (${argocdVersion})";
    after = ["k3s.service"];
    wants = ["k3s.service"];
    wantedBy = ["multi-user.target"];

    path = [pkgs.k3s];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    script = ''
      export KUBECONFIG="/etc/rancher/k3s/k3s.yaml"

      # Wait for k3s API to be ready
      for i in $(seq 1 60); do
        kubectl get --raw='/readyz' &>/dev/null && break
        [ "$i" -eq 60 ] && { echo "k3s not ready after 5m, aborting"; exit 1; }
        sleep 5
      done

      kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
      kubectl apply -n argocd -f ${argocdManifest}
      kubectl -n argocd rollout status deployment/argocd-server --timeout=300s || true

      # Repo credentials + NodePort for the UI (Traefik proxies homeserver:30080)
      kubectl apply -f ${config.sops.templates."argocd-gitops-repo.yaml".path}
      kubectl apply -f ${./server-nodeport.yaml}

      # Root Application (app-of-apps): 4rmcyt/gitops//k3s
      kubectl apply -f ${./application.yaml}
    '';
  };
}
