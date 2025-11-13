{pkgs, ...}: {
  default = {
    # Use nushell as the default shell
    devshell.motd = ''
      {202}🔨 NixOS Config Development Shell{reset}
      $(type -p menu &>/dev/null && menu)
    '';

    packages = with pkgs; [
      # Shell
      carapace
      direnv
      nix-direnv
      sops
      openssl
      sqlite
      git

      # Code formatters
      cmake-format
      nodePackages.prettier
      rustfmt
      yamlfmt
      toml-sort
      shfmt
      shellcheck
      just
      dockfmt
      alejandra
      treefmt
      statix

      # Development tools
      nix-diff
    ];

    commands = [
      {
        package = pkgs.nixfmt-rfc-style;
        help = "Format Nix files using RFC style";
      }
      {
        package = pkgs.deadnix;
        help = "Find and remove unused code in Nix files";
      }
      {
        package = pkgs.treefmt;
        help = "Format all files in the project";
      }
    ];

    # Set nushell as the shell
    devshell.name = "nix-config";
    bash.extra = ''
      # Launch nushell if available and in an interactive shell
      if command -v nu &> /dev/null && [[ $- == *i* ]]; then
        exec nu
      fi
    '';
  };
}
