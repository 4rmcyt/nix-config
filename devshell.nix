{
  pkgs,
  inputs,
  ...
}:
pkgs.mkShell {
  name = "nix-config";

  packages =
    [inputs.deploy-rs.packages.${pkgs.system}.deploy-rs]
    ++ (with pkgs; [
      zsh
      nix-direnv
      nixfmt
      statix
      deadnix
      nix-tree
      nix-diff
      nix-output-monitor
      nix-prefetch-git
      nix-update
      nh
      nvd
      sops
      age
      ssh-to-age
      git
      gh
      shellcheck
      shfmt
      jq
      yq
      btop
      fd
      ripgrep
      bat
      eza
      just
      alejandra
      nurl
      pre-commit
      taplo
      yamlfmt
      ripsecrets
      pre-commit-hook-ensure-sops
    ]);

  shellHook = ''
    echo "🔨 NixOS Config Development Shell"
  '';
}
