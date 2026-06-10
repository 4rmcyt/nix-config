{inputs, ...}: {
  imports = [inputs.determinate.nixosModules.default];
  nix.settings = {
    extra-experimental-features = ["ca-derivations"];
    lazy-locks = true;
  };
}
