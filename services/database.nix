services.postgresql = {
  enable = true;
  package = pkgs.postgresql_15;
  ensureDatabases = [ "keycloak" "miniflux" "paperless" "hass" ];

  ensureUsers = [
    {
      name = "keycloak";
      # This correctly uses the content of the secret file for the password
      passwordFile = config.sops.secrets.keycloak_db_password.path;
    }
    {
      name = "miniflux";
      passwordFile = config.sops.secrets.miniflux_db_password.path;
    }
    {
      name = "paperless";
      # Assuming you have this secret defined in sops.nix
      passwordFile = config.sops.secrets.paperless_db_password.path;
    }
  ];

  # You can likely remove identMap unless you have specific needs for it.
  identMap = ''
    # ArbitraryMapName systemUser DBUser
      superuser_map      root      postgres
      superuser_map      postgres  postgres
    # Let other names login as themselves
      superuser_map      /^(.*)$   \1
  '';
};