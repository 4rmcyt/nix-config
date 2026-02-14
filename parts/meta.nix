# Provides meta as an internal flake-parts option for shared metadata.
# NOT under flake.* so it won't appear as a flake output.
{lib, ...}: {
  options.meta = lib.mkOption {
    type = lib.types.anything;
    default = {};
  };
}
