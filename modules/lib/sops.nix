{
  config,
  lib,
  ...
}: {
  options.lib.mkServiceSecret = lib.mkOption {
    type = lib.types.functionTo lib.types.attrs;
    description = "Helper function to create SOPS secrets for services";
    default = {
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
  };

  options.lib.mkSecretsPath = lib.mkOption {
    type = lib.types.functionTo lib.types.path;
    description = "Helper to resolve paths to secrets directory";
    default = file: ../../../secrets + "/${file}";
  };
}
