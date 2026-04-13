# nix-topology integration via flakeModule.
# Generates topology.${system}.config.output with SVG infrastructure diagrams.
# Build: nix build .#topology.x86_64-linux.config.output
{
  inputs,
  config,
  ...
}: {
  imports = [inputs.nix-topology.flakeModule];

  perSystem = {
    topology.modules = [
      {inherit (config.flake) nixosConfigurations;}
    ];
  };
}
