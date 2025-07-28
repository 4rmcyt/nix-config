{
  pkgs,
  config,
  ...
}: {
  programs.ssh.knownHosts = {
    "u478963.your-storagebox.de".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJLqJ3YhcAyUW6cnSPyuLp5+zCF3ULTGjkxcKNqeBzks";
  };

  services.restic.backups.full = {
    initialize = true;
    passwordFile = config.sops.secrets.restic-hetzner-password.path;
    repository = "sftp://<boxname>-<subN>@<boxname>.your-storagebox.de/"; 
    timeConfig.OnCalendar = "daily";
    paths = [ "/etc/nixos" "/var/lib/" "/home" ];
    extraBackupArgs = let
      ignorePatterns = [
        "/var/lib/systemd"
        "/var/lib/containers"
        "/var/lib/flatpak"
        "/home/*/.local/share/Trash"
        "/home/*/.cache"
        "/home/*/Downloads"
        "/home/*/.npm"
        "/home/*/.local/share/containers"
        ".cache"
        ".tmp"
        ".log"
        ".Trash"
      ];
    ignoreFile = builtins.toFile "ignore"
      (foldl (a: b: a + "\n" + b) "" ignorePatterns);
    in [ "--exclude-file=${ignoreFile}" ];
    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 4"
      "--keep-monthly 3"
      "--keep-yearly 1"
    ];
    
    
    timerConfig = { # when to backup
      OnCalendar = "00:05";
      RandomizedDelaySec = "5h";
    };
    };
}
