{
  config,
  osConfig,
  ...
}: {
  sops = {
    secrets = {
      atuin_key = {
        sopsFile = ../../secrets/atuin.yaml;
        key = "atuin_key";
      };
      atuin_session = {
        sopsFile = ../../secrets/atuin.yaml;
        key = "atuin_session";
      };
    };
  };
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
        sync_address = "https://atuin.${osConfig.my.defaults.domain}";
        update_check = false;
        filter_mode = "global";
        enter_accept = true;
        show_help = true;
        prefers_reduced_motion = true;

        style = "compact";
        inline_height = 10;
        search_mode = "fuzzy";
        filter_mode_shell_up_key_binding = "session";
        session_path = config.sops.secrets.atuin_session.path;
        key_path = config.sops.secrets.atuin_key.path;
      };
    };
  };
}
