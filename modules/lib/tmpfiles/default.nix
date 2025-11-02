{
  lib,
  ...
}: let
  mkServiceDirs = args: let
    inherit (args) service;
    user = args.user or service;
    group = args.group or service;
    subdirs = args.subdirs or ["config" "logs" "data"];
    mode = args.mode or "0755";
  in
    ["d /var/lib/${service} ${mode} ${user} ${group} -"]
    ++ (map (subdir: "d /var/lib/${service}/${subdir} ${mode} ${user} ${group} -") subdirs);
in {
  lib =
    lib
    // {
      inherit mkServiceDirs;
    };
}
