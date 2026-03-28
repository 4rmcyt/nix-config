# Provides the configurations.nixOnDroid option.
# Each entry produces a flake.nixOnDroidConfigurations.<name> output.
# Deploy with: nix-on-droid switch --flake .#<name>
{
  lib,
  config,
  inputs,
  ...
}: {
  options.configurations.nixOnDroid = lib.mkOption {
    type = lib.types.lazyAttrsOf (
      lib.types.submodule {
        options.module = lib.mkOption {
          type = lib.types.deferredModule;
        };
      }
    );
    default = {};
  };

  config.flake.nixOnDroidConfigurations =
    lib.mapAttrs (
      _name: {module}:
        inputs.nix-on-droid.lib.nixOnDroidConfiguration {
          pkgs = import inputs.nixpkgs {system = "aarch64-linux";};
          modules = [module];
          extraSpecialArgs = {inherit inputs;};
        }
    )
    config.configurations.nixOnDroid;
}
