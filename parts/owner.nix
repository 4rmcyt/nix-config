# Owner metadata for the flake-parts scope. Only `username` is consumed here
# (HM wiring, nh flake path, per-user imports). NixOS-scope modules read identity
# and topology from the private `private` flake input via my.defaults.* /
# my.network.* (modules/options/).
{inputs, ...}: {
  meta.stateVersion = "25.11";
  meta.owner.username = inputs.private.lib.identity.username;
}
