{pkgs, ...}: {
  # ArgoCD GitOps
  systemd.services.argocd-install = {
    description = "Install ArgoCD";
    after = ["k3s.service"];
    wants = ["k3s.service"];
    wantedBy = ["multi-user.target"];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    script = ''
      export PATH="${pkgs.k3s}/bin:$PATH"
      export KUBECONFIG="/etc/rancher/k3s/k3s.yaml"

      # Wait for k3s to be ready
      for i in {1..12}; do
        if kubectl get nodes &>/dev/null; then
          break
        fi
        if [ $i -eq 12 ]; then
          echo "k3s not ready, skipping ArgoCD install"
          exit 0
        fi
        sleep 5
      done

      # Install ArgoCD if not already installed
      if ! kubectl get namespace argocd &>/dev/null; then
        kubectl create namespace argocd
        kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

        # Wait for ArgoCD to be ready
        kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd || true

        # Create ArgoCD Application for gitops repo
        kubectl apply -f ${./application.yaml}
      fi
    '';
  };
}
