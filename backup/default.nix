{
  pkgs,
  config,
  ...
}:
{ 
  
  services.restic.backups.full = {
    initialize = true;
    passwordFile = config.sops.secrets.hetzner_password.path;
    repository = "sftp://u478963@u478963.your-storagebox.de:23/homelab/server/";
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
    isSystemUser = true;
    group = "restic";
    extraGroups = [ "users" "restic" ];
  };
  users.groups.restic = {};
  openssh.knownHosts."u478963.your-storagebox.de" = {
    key = "u478963.your-storagebox.de ssh-ed25519 AAAAB3NzaC1yc2EAAAABIwAAAQEA5EB5p/5Hp3hGW1oHok+PIOH9Pbn7cnUiGmUEBrCVjnAw+HrKyN8bYVV0dIGllswYXwkG/+bgiBlE6IVIBAq+JwVWu1Sss3KarHY3OvFJUXZoZyRRg/Gc/+LRCE7lyKpwWQ70dbelGRyyJFH36eNv6ySXoUYtGkwlU5IVaHPApOxe4LHPZa/qhSRbPo2hwoh0orCtgejRebNtW5nlx00DNFgsvn8Svz2cIYLxsPVzKgUxs8Zxsxgn+Q/UvR7uq4AbAhyBMLxv7DjJ1pc7PJocuTno2Rw9uMZi1gkjbnmiOh6TTXIEWbnroyIhwc8555uto9melEUmWNQ+C+PwAK+MPw==";
  };
}
