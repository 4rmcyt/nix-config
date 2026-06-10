{inputs, ...}: {
  imports = [inputs.determinate.nixosModules.default];
  nix.settings = {
    extra-experimental-features = [
      "ca-derivations"
      "pipe-operators"
    ];
    lazy-locks = true;
  };
}
