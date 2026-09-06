# ARC GitHub App credentials for the `arc-runner-set` Application in
# 4rmcyt/gitops. Not imported by default -- enable on homeserver once the
# GitHub App exists and secrets/k3s.yaml has the three arc_github_app_* keys.
{
  config,
  pkgs,
  ...
}: {
  sops.secrets = {
    arc_github_app_id = {
      sopsFile = ../../../secrets/k3s.yaml;
      key = "arc_github_app_id";
      mode = "0400";
    };
    arc_github_app_installation_id = {
      sopsFile = ../../../secrets/k3s.yaml;
      key = "arc_github_app_installation_id";
      mode = "0400";
    };
    arc_github_app_private_key = {
      sopsFile = ../../../secrets/k3s.yaml;
      key = "arc_github_app_private_key";
      mode = "0400";
    };
  };

  systemd.services.arc-github-app-secret = {
    description = "Provision ARC GitHub App secret";
    after = ["argocd-install.service"];
    wants = ["argocd-install.service"];
    wantedBy = ["multi-user.target"];
    path = [pkgs.k3s];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      export KUBECONFIG="/etc/rancher/k3s/k3s.yaml"
      for i in $(seq 1 60); do
        kubectl get --raw='/readyz' &>/dev/null && break
        sleep 5
      done

      kubectl create namespace arc-runners --dry-run=client -o yaml | kubectl apply -f -
      kubectl create secret generic arc-github-app -n arc-runners \
        --from-literal=github_app_id="$(cat ${config.sops.secrets.arc_github_app_id.path})" \
        --from-literal=github_app_installation_id="$(cat ${config.sops.secrets.arc_github_app_installation_id.path})" \
        --from-file=github_app_private_key=${config.sops.secrets.arc_github_app_private_key.path} \
        --dry-run=client -o yaml | kubectl apply -f -
    '';
  };
}
