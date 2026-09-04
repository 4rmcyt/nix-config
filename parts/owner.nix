# Owner metadata — non-secret wiring values. The identity/topology values
# themselves live in the private `private` flake input (eval-time plaintext that
# must not be in this public repo); this only maps them onto meta.owner.
{inputs, ...}: let
  inherit (inputs.private.lib) identity network;
in {
  meta.stateVersion = "25.11";

  meta.owner = {
    inherit (identity) username;
    inherit (identity) email;
    inherit (identity) gitUsername;
    inherit (identity) gitSigningKey;
    inherit (identity) domain;
    inherit (identity) timezone;
    inherit (identity) locale;
    inherit (network) gateway;
    homeserverLan = network.hosts.homeserver_lan;
    desktopLan = network.hosts.desktop_lan;
    desktopWifi = network.hosts.desktop_wifi;
    matebookWifi = network.hosts.matebook_wifi;
  };
}
