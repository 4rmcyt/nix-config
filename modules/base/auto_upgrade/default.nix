_:
{
  system.autoUpgrade = {
    enable = true;
    flake = "github:4rmcyt/server#homeserver";
    dates = "Sat *-*-* 03:00";
    allowReboot = true;
    rebootWindow = {
      lower = "03:00";
      upper = "05:00";
    };
    flags = [
      "-L" # print build logs
      "--refresh" # update the repository
    ];
  };
}
