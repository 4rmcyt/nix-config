{
  config,
  lib,
  ...
}: let
  mkServiceSecret = {
    secretName,
    service,
    sopsFile,
    key ? secretName,
    mode ? "0400",
  }: {
    sops.secrets.${secretName} = {
      inherit sopsFile key mode;
      owner = config.users.users.${service}.name;
      group = config.users.groups.${service}.name;
    };
  };

  mkSecretsPath = file: ../../../secrets + "/${file}";
in {
  lib =
    lib
    // {
      inherit mkServiceSecret;
      inherit mkSecretsPath;
    };
}
