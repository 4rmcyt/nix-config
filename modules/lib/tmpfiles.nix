{
  config,
  lib,
  ...
}: {
  options.lib.mkServiceDirs = lib.mkOption {
    type = lib.types.functionTo (lib.types.listOf lib.types.str);
    description = "Helper function to create systemd tmpfiles.d rules for service directories";
    default = {
      service,
      user ? service,
      group ? service,
      subdirs ? ["config" "logs" "data"],
      mode ? "0755",
    }:
      ["d /var/lib/${service} ${mode} ${user} ${group} -"]
      ++ (map (subdir: "d /var/lib/${service}/${subdir} ${mode} ${user} ${group} -") subdirs);
  };
}
