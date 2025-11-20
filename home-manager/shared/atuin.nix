{
  config,
  ...
}: {
  programs = {
    browserpass.enable = true;
    nushell.enable = true;
    atuin = {
      enable = true;
      enableZshIntegration = true;
      enableNushellIntegration = true;

      flags = ["--disable-up-arrow"]; # or --disable-ctrl-r

      settings = {
        auto_sync = true;
        sync_frequency = "30m";
        sync_address = "https://atuin.${config.my.network.domain}";
        update_check = false;
        filter_mode = "global";
        enter_accept = true;
        show_help = true;
        prefers_reduced_motion = true;

        style = "compact";
        inline_height = 10;
        search_mode = "fuzzy";
        filter_mode_shell_up_key_binding = "session";
        # client_config = "/home/zeev/.config/atuin/config.toml";
        # client_db_path = "/home/zeev/.local/share/atuin/history.db";
        session_path = config.sops.secrets.atuin_session.path;
        key_path = config.sops.secrets.atuin_key.path;
      };
    };
  };
}
