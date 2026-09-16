# NOT a replacement for the systemd deployment; the two run side by side until the
# k3s path is verified and cut over.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.jobKombayn;
in {
  options.services.jobKombayn.enableK3sSecretSync = lib.mkEnableOption "sync job-kombayn.env into a k8s Secret for the k3s deployment";

  config = lib.mkIf cfg.enableK3sSecretSync {
    systemd.services.job-kombayn-k8s-secret = {
      description = "job-kombayn: sync env secret into the k3s job-kombayn namespace";
      after = ["k3s.service"];
      wants = ["k3s.service"];
      wantedBy = ["multi-user.target"];
      path = [pkgs.k3s];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

        for i in $(seq 1 60); do
          kubectl get --raw='/readyz' &>/dev/null && break
          [ "$i" -eq 60 ] && { echo "k3s not ready after 5m, aborting"; exit 1; }
          sleep 5
        done

        kubectl create namespace job-kombayn --dry-run=client -o yaml | kubectl apply -f -
        kubectl create secret generic job-kombayn-env \
          --from-env-file=${config.sops.secrets.job_kombayn_env.path} \
          --namespace=job-kombayn \
          --dry-run=client -o yaml | kubectl apply -f -
      '';
    };
  };
}
