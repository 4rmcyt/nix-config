{
  pkgs,
  config,
  osConfig,
  ...
}: {

  sops.secrets = {
    atuin_session = {
      sopsFile = ../../../secrets/atuin.yaml;
      key = "atuin_session";
      owner = config.my.user.name;
      group = config.my.user.name;
      mode = "0400";
    };

    atuin_key = {
      sopsFile = ../../../secrets/atuin.yaml;
      key = "atuin_key";
      owner = config.my.user.name;
      group = config.my.user.name;
      mode = "0400";
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
