{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ((import ../lib/pg-env.nix {inherit lib;}) {
      name = "bazarr";
      envLines = [
        "POSTGRES_ENABLED=true"
        "POSTGRES_HOST=127.0.0.1"
        "POSTGRES_PORT=5432"
        "POSTGRES_DATABASE=bazarr"
        "POSTGRES_USERNAME=bazarr"
        "POSTGRES_PASSWORD=%s"
      ];
      passwordSecretPath = config.sops.secrets.bazarr_db_password.path;
    })
  ];

  # Custom post-processing (Bazarr Settings > Subtitles) converts .srt to
  # .ass for languages whose glyphs some clients can't render as text
  # (e.g. Hebrew on Roku -- tofu boxes), so the server burns them in via
  # libass instead of the client rendering plain text. ffmpeg isn't
  # otherwise on bazarr's PATH.
  systemd.services.bazarr.path = [pkgs.ffmpeg];

  # Bazarr reads these same POSTGRES_* env vars natively and gives them
  # precedence over config.yaml -- no container entrypoint magic needed.
  services.bazarr = {
    enable = true;
    user = "bazarr";
    group = "bazarr";
    dataDir = "/data/media/.state/nixarr/bazarr";
    listenPort = config.my.network.ports.bazarr;
  };

  systemd.services.bazarr = {
    after = ["data.mount" "bazarr-pg-env.service"];
    requires = ["data.mount" "bazarr-pg-env.service"];
    serviceConfig.EnvironmentFile = "/run/bazarr-secrets/pg-env";
  };
}
