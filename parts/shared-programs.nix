# Common programs enabled on all hosts via modules.nixos.base.
_: {
  modules.nixos.base = {
    programs.zsh.enable = true;
  };
}
