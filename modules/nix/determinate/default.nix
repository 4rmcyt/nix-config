{inputs, ...}: {
  imports = [inputs.determinate.nixosModules.default];

  nix.settings = {
    extra-substituters = ["https://install.determinate.systems"];
    extra-trusted-public-keys = ["cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM="];
    extra-experimental-features = [
      "lazy-trees"
      "flake-schemas"
      "ca-derivations"
    ];
  };
}
