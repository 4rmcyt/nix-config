# Common programs enabled on all hosts via modules.nixos.base.
_: {
  modules.nixos.base = {config, ...}: {
    programs.zsh.enable = true;

    programs.nh = {
      enable = true;
      clean.enable = true;
      clean.extraArgs = "--keep-since 10d --keep 3";
      flake = "/home/${config.my.defaults.user}/src/nix-config";
    };

    programs.gnupg.agent.enable = true;
  };
}
