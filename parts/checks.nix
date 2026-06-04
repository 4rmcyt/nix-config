{
  inputs,
  config,
  ...
}: {
  perSystem = {system, ...}: {
    checks = inputs.deploy-rs.lib.${system}.deployChecks config.flake.deploy;
  };
}
