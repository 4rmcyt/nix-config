# Named deferred modules organized by class (e.g., nixos, homeManager).
# Defined as an internal flake-parts option (NOT under flake.*) to avoid
# "unknown flake output 'modules'" warnings.
{ lib, ... }:
{
  options.modules = lib.mkOption {
    type = lib.types.attrsOf (lib.types.attrsOf lib.types.deferredModule);
    default = { };
  };
}
