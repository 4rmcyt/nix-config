{
  pkgs,
  config,
  ...
}:
{ 
  programs.ssh.knownHosts."u478963.your-storagebox.de" = {
    "u478963.your-storagebox.de".publicKey =
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINqWND9TV1kHdHx5b1slLau2pLJhEsxGTm1nBqFKP6G9";
  };
  
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
  
}
