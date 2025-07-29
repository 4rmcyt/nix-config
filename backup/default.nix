{
  pkgs,
  config,
  ...
}:
{ 
  services.borgbackup.jobs.server-home = {
    paths = "/home/zeev";
    encryption.mode = "none";
    environment.BORG_RSH = "ssh -i /home/zeev/.ssh/id_ed25519";
    repo = "ssh://uu478963@u478963.your-storagebox.de:23/server";
    compression = "auto,zstd";
    startAt = "daily";
  };
    
    # paths = [
    #   "/etc/nixos"
    #   "/var/lib/"
    #   "/home"
    # ];
    # extraBackupArgs = [
    #   "--exclude-caches"
    #   "--exclude-if-present .nobackup"
    #   "--exclude-file=/var/lib/systemd"
    #   "--exclude-file=/var/lib/containers"
    #   "--exclude-file=/var/lib/flatpak"
    #   "--exclude-file=/home/*/.local/share/Trash"
    #   "--exclude-file=/home/*/.cache"
    #   "--exclude-file=/home/*/Downloads"
    #   "--exclude-file=/home/*/.npm"
    #   "--exclude-file=/home/*/.local/share/containers"
    #   "--exclude-file=.cache"
    #   "--exclude-file=.tmp"
    #   "--exclude-file=.log"
    #   "--exclude-file=.Trash"
    # ];
    # pruneOpts = [
    #   "--keep-daily 7"
    #   "--keep-weekly 4"
    #   "--keep-monthly 3"
    #   "--keep-yearly 1"
    # ];
    

  
}
