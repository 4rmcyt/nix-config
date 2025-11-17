 #!${pkgs.nushell}/bin/nu

      # Set rclone config path
      $env.RCLONE_CONFIG = $"($env.HOME)/.config/rclone/rclone.conf"

      # Check if rclone config exists
      if not ($env.RCLONE_CONFIG | path exists) {
        print "Error: rclone config not found at ($env.RCLONE_CONFIG)"
        print "Please run: rclone config"
        exit 1
      }

      # Check if gdrive remote is configured
      let remotes = (${pkgs.rclone}/bin/rclone listremotes | str trim)
      if not ($remotes | str contains "gdrive:") {
        print "Error: rclone is not configured for Google Drive (gdrive:)"
        print "Please run: rclone config"
        exit 1
      }

      print "Starting shell history backup..."

      # Create backup directory
      let backup_dir = $"($env.HOME)/.shell-history-backups"
      mkdir $backup_dir

      let timestamp = (date now | format date "%Y%m%d-%H%M%S")

      # Backup Zsh history
      let zsh_history = $"($env.HOME)/.zsh_history"
      if ($zsh_history | path exists) {
        print "Backing up Zsh history..."
        let backup_file = $"($backup_dir)/zsh_history_($timestamp)"
        cp $zsh_history $backup_file
        ${pkgs.rclone}/bin/rclone copy $backup_file "gdrive:shell-history-backups/"
      }

      # Backup Nushell history
      let nushell_history = $"($env.HOME)/.local/share/nushell/history.sqlite3"
      if ($nushell_history | path exists) {
        print "Backing up Nushell history..."
        let backup_file = $"($backup_dir)/nushell_history_($timestamp).sqlite3"
        cp $nushell_history $backup_file
        ${pkgs.rclone}/bin/rclone copy $backup_file "gdrive:shell-history-backups/"
      }

      # Keep only last 7 local backups
      print "Cleaning old local backups..."

      # Clean old zsh backups
      let zsh_backups = (glob $"($backup_dir)/zsh_history_*" | each {|f| ls $f} | flatten | sort-by modified -r | select name)
      if ($zsh_backups | length) > 7 {
        $zsh_backups | skip 7 | each {|file| rm $file.name}
      }

      # Clean old nushell backups
      let nu_backups = (glob $"($backup_dir)/nushell_history_*.sqlite3" | each {|f| ls $f} | flatten | sort-by modified -r | select name)
      if ($nu_backups | length) > 7 {
        $nu_backups | skip 7 | each {|file| rm $file.name}
      }

      print $"Backup completed successfully at (date now | format date '%Y-%m-%d %H:%M:%S')"
