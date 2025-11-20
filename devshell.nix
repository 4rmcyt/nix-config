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
      nix-direnv
      sqlite

      # Code formatters
      shellcheck
    ];

    commands = [];

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
