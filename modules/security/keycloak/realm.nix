{...}: {
  # The realm template is stored as a plain JSON file in the Nix store
  # Secrets are injected at runtime by the keycloak-prepare-realm service
  _module.args.keycloakRealmTemplate = ./homelab-realm.json;
}
