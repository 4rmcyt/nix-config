# Lets the host Traefik (systemd service, NOT running inside k3s) route
# directly to k3s workloads via IngressRoute CRDs — job-kombayn and any
# future k3s service just ships an IngressRoute in gitops, no per-service
# nix-config edit (no NodePort, no mkProxiedRouter entry) needed.
#
# Traefik gets its own minimal, read-only ServiceAccount (./k8s-rbac.yaml) —
# deliberately NOT the admin kubeconfig ArgoCD uses — rendered into a
# kubeconfig file via KUBECONFIG env var, same client-go auto-detection every
# other Kubernetes tool uses (no config.my.traefik-specific static-config
# token field needed, which would otherwise land the raw bearer token in the
# world-readable Nix store).
{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf config.my.traefik.enable {
    services.traefik.staticConfigOptions.providers.kubernetesCRD = {};

    systemd.services.traefik-k8s-rbac = {
      description = "Traefik: apply minimal RBAC + render kubeconfig for the Kubernetes CRD provider";
      after = ["k3s.service"];
      wants = ["k3s.service"];
      wantedBy = ["multi-user.target"];
      path = [pkgs.k3s pkgs.coreutils];
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

        kubectl apply -f ${./k8s-rbac.yaml}

        TOKEN=""
        for i in $(seq 1 30); do
          TOKEN=$(kubectl get secret traefik-external-token -n kube-system -o jsonpath='{.data.token}' 2>/dev/null | base64 -d)
          [ -n "$TOKEN" ] && break
          sleep 2
        done
        [ -z "$TOKEN" ] && { echo "traefik-external-token never populated, aborting"; exit 1; }

        # Embed the CA as base64 data (not a file path) so the rendered
        # kubeconfig is self-contained and traefik (a separate, unprivileged
        # system user) never needs read access to k3s's own TLS directory.
        CA_DATA=$(base64 -w0 /var/lib/rancher/k3s/server/tls/server-ca.crt)

        install -d -m 0750 -o traefik -g traefik /var/lib/traefik-k8s
        umask 077
        cat > /var/lib/traefik-k8s/kubeconfig <<EOF
        apiVersion: v1
        kind: Config
        clusters:
        - name: k3s
          cluster:
            server: https://127.0.0.1:6443
            certificate-authority-data: $CA_DATA
        contexts:
        - name: traefik
          context:
            cluster: k3s
            user: traefik
        current-context: traefik
        users:
        - name: traefik
          user:
            token: $TOKEN
        EOF
        chown traefik:traefik /var/lib/traefik-k8s/kubeconfig
        chmod 0400 /var/lib/traefik-k8s/kubeconfig
      '';
    };

    systemd.services.traefik = {
      after = ["traefik-k8s-rbac.service"];
      wants = ["traefik-k8s-rbac.service"];
      environment.KUBECONFIG = "/var/lib/traefik-k8s/kubeconfig";
    };
  };
}
