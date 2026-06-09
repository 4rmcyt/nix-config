{
  inputs,
  config,
  lib,
  ...
}: {
  perSystem = {system, ...}: {
    checks = lib.filterAttrs (_: lib.isDerivation) (
      inputs.deploy-rs.lib.${system}.deployChecks config.flake.deploy
    );
  };
}
