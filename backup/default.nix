{
  pkgs,
  config,
  ...
}:
{ 
  services.restic.backups.full = {
    initialize = true;
    user = "restic";
    package = pkgs.writeShellScriptBin "restic" ''
      exec /run/wrappers/bin/restic "$@"
    '';
    passwordFile = config.sops.secrets.hetzner_password.path;
    repository = "sftp://u478963@u478963.your-storagebox.de:23/server";
    runCheck = true;
    
    paths = [
      "/etc/nixos"
      "/var/lib/"
      "/home"
    ];
    extraBackupArgs = [
      "--exclude-caches"
      "--exclude-if-present .nobackup"
      "--exclude-file=/var/lib/systemd"
      "--exclude-file=/var/lib/containers"
      "--exclude-file=/var/lib/flatpak"
      "--exclude-file=/home/*/.local/share/Trash"
      "--exclude-file=/home/*/.cache"
      "--exclude-file=/home/*/Downloads"
      "--exclude-file=/home/*/.npm"
      "--exclude-file=/home/*/.local/share/containers"
      "--exclude-file=.cache"
      "--exclude-file=.tmp"
      "--exclude-file=.log"
      "--exclude-file=.Trash"
    ];
    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 4"
      "--keep-monthly 3"
      "--keep-yearly 1"
    ];
    

    timerConfig = {
      OnCalendar = "00:05";
      RandomizedDelaySec = "5h";
    };
  };

  users.users.restic = {
    isNormalUser = true;
  };
  security.wrappers.restic = {
    source = "${pkgs.restic.out}/bin/restic";
    owner = "restic";
    group = "users";
    permissions = "u=rwx,g=,o=";
    capabilities = "cap_dac_read_search=+ep";
  };

  
}
