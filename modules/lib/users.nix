{
  config,
  lib,
  ...
}: {
  options.lib.mkServiceUser = lib.mkOption {
    type = lib.types.functionTo lib.types.attrs;
    description = "Helper function to create system service users and groups";
    default = {
      serviceName,
      extraGroups ? ["users"],
    }: {
      users.users.${serviceName} = {
        isSystemUser = true;
        group = serviceName;
        inherit extraGroups;
      };
      users.groups.${serviceName} = {};
    };
  };
}
