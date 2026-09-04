{
  pkgs,
  osConfig,
  ...
}: {
  home.packages = with pkgs; [
    obsidian
  ];

  # Obsidian configuration directory: ~/.config/obsidian
  # Plugins are typically installed per-vault via Obsidian's UI
  # However, you can pre-configure community plugins here if needed

  home.file.".config/obsidian/obsidian-livesync-info.md".text = ''
    # Obsidian LiveSync Setup

    ## Install the Plugin
    1. Open Obsidian Settings → Community Plugins
    2. Disable Safe Mode (if enabled)
    3. Click "Browse" and search for "Self-hosted LiveSync"
    4. Install and Enable the plugin

    ## Configure Self-hosted LiveSync
    1. Open plugin settings for "Self-hosted LiveSync"
    2. Configure the remote database:
       - **URI**: https://livesync.${osConfig.my.defaults.domain}/obsidian
       - **Username**: Your CouchDB username
       - **Password**: Your CouchDB password
       - **Database name**: obsidian (or your created database name)

    3. Enable End-to-End Encryption (recommended):
       - Set a passphrase (keep it safe!)
       - This encrypts your vault data on the server

    4. Configure sync settings:
       - Enable "LiveSync" for real-time sync
       - Configure conflict resolution preferences
       - Set sync on save, periodic sync, etc.

    ## Initial Sync
    1. After configuration, click "Check database configuration"
    2. If successful, perform initial sync:
       - Click "Replicate now" to upload your vault
       - Wait for sync to complete

    ## Multiple Devices
    - Install Obsidian LiveSync on all devices
    - Use the same connection settings
    - Use the same encryption passphrase (if enabled)

    ## Server URL
    - CouchDB Admin UI: https://livesync.${osConfig.my.defaults.domain}/_utils
    - Database endpoint: https://livesync.${osConfig.my.defaults.domain}/obsidian

    ## Troubleshooting
    - Check CouchDB is running: systemctl status couchdb
    - View logs: journalctl -u couchdb -f
    - Verify nginx proxy: systemctl status nginx
    - Test connection: curl https://livesync.${osConfig.my.defaults.domain}

    ## References
    - Plugin: https://github.com/vrtmrz/obsidian-livesync
    - Setup Guide: https://github.com/vrtmrz/obsidian-livesync/blob/main/docs/setup_own_server.md
    - Quick Setup: https://github.com/vrtmrz/obsidian-livesync/blob/main/docs/quick_setup.md
  '';
}
