# NixOS-scope modules read identity/topology via my.defaults.*/my.network.* (modules/options/).
{inputs, ...}: {
  meta.stateVersion = "25.11";
  meta.owner.username = inputs.private.lib.identity.username;
}
