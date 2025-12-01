{config, ...}: {
  # Define SOPS secret for the realm configuration
  sops.secrets.keycloak_realm = {
    sopsFile = ../../../secrets/keycloak-realm.json;
    format = "binary";
    owner = config.users.users.keycloak.name;
    group = config.users.groups.keycloak.name;
    mode = "0400";
  };

  # The realm template path will point to the decrypted SOPS secret
  # Runtime substitution happens in the keycloak-prepare-realm service
  _module.args.keycloakRealmTemplate = config.sops.secrets.keycloak_realm.path;
}
