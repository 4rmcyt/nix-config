# Treefmt-based code formatting via flake-parts perSystem.
{ inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      formatter =
        let
          treefmtEval = inputs.treefmt-nix.lib.evalModule pkgs (import ../treefmt.nix);
        in
        treefmtEval.config.build.wrapper;
    };
}
