{inputs, ...}: {
  flake.schemas =
    inputs.flake-schemas.schemas
    // {
      topology = {
        version = 1;
        doc = "nix-topology infrastructure diagrams. Build with `nix build .#topology.<system>.config.output`.";
        inventory = output: {
          children =
            builtins.mapAttrs (system: _: {
              forSystems = [system];
              what = "topology configuration";
            })
            output;
        };
      };
    };
}
