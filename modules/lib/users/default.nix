{lib, ...}: let
  mkServiceUser = {
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
in {
  lib =
    lib
    // {
      inherit mkServiceUser;
    };
}
