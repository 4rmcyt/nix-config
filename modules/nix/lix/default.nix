{
  pkgs,
  lib,
  ...
}: {
  nix.package = lib.mkDefault pkgs.lixPackageSets.latest.lix;

  nix.settings = {
    extra-substituters = ["https://cache.lix.systems?priority=1"];
    extra-trusted-public-keys = ["cache.lix.systems:aBnZUw8zA7H35Cz2RyKFVs3H4PlGTLawyY5KRbvJR8o="];
    # Lix-only features not recognized by upstream/Determinate Nix
    extra-experimental-features = ["pipe-operator"];
    deprecated-features = ["broken-string-escape"];
    initial-connect-timeout = 15;
  };
}
