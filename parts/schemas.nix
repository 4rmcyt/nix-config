{inputs, ...}: {
  flake.schemas =
    inputs.flake-schemas.schemas
    // {
      deploy = {
        version = 1;
        doc = "deploy-rs deployment nodes for NixOS systems. Build with `deploy .#<node>`.";
        inventory = output: {
          children = builtins.mapAttrs (nodeName: node: {
            shortDescription = node.hostname or nodeName;
            what = "deploy node";
          }) (output.nodes or {});
        };
      };

      topology = {
        version = 1;
        doc = "nix-topology infrastructure diagrams. Build with `nix build .#topology.<system>.config.output`.";
        inventory = output: {
          children = builtins.mapAttrs (system: _: {
            forSystems = [system];
            what = "topology configuration";
          }) output;
        };
      };
    };
}
