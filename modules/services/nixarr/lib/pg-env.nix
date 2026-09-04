# Shared systemd oneshot that writes a Postgres EnvironmentFile for a
# Servarr-family service before it starts. Each caller supplies the exact
# env var names it reads (they differ per app) and the sops secret path
# holding its DB password.
{lib}: {
  name,
  user ? name,
  group ? user,
  envLines,
  passwordSecretPath,
}: {
  systemd.services."${name}-pg-env" = {
    description = "Write ${name} PostgreSQL environment file";
    after = [
      "postgresql.service"
      "postgresql-setup-users.service"
    ];
    requires = ["postgresql.service"];
    wantedBy = ["${name}.service"];
    before = ["${name}.service"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      RuntimeDirectory = "${name}-secrets";
      RuntimeDirectoryMode = "0750";
      User = user;
      Group = group;
    };
    script = ''
      printf '${lib.concatStringsSep "\\n" envLines}\n' \
        "$(cat ${passwordSecretPath} | tr -d '\n\r')" \
        > /run/${name}-secrets/pg-env
      chmod 600 /run/${name}-secrets/pg-env
    '';
  };
}
