{...}: {
  imports = [
    ./atuin-server
    ./dispatcharr
    ./home-assistant
    ./homepage
    ./job-kombayn
    ./komf
    ./komga
    ./microbin
    ./miniflux
    ./nixarr
    ./ntfy
    ./radicale
    # Ready but off — flip on to bring up k3s + ArgoCD on homeserver.
    # See docs/Infrastructure.md "Kubernetes (k3s + ArgoCD)".
    # ./k3s
    # ./argocd
  ];
}
