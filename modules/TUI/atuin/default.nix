{
  config,
  osConfig ? null,
  lib,
  ...
}: let
  hostName = osConfig.networking.hostName;
  keyName = "atuin_key_${hostName}";
  sessionName = "atuin_session_${hostName}";
in {
  sops = {
    secrets = {
      ${keyName} = {
        sopsFile = ../../../secrets/atuin.yaml;
        key = keyName;
      };
      ${sessionName} = {
        sopsFile = ../../../secrets/atuin.yaml;
        key = sessionName;
      };
    };
  };
  programs = {
    atuin = {
      enable = true;
      enableZshIntegration = true;
      enableNushellIntegration = true;
      flags = ["--disable-up-arrow"];
      settings =
        {
          auto_sync = true;
          sync_frequency = "30m";
          update_check = false;
          filter_mode = "global";
          enter_accept = true;
          show_help = true;
          prefers_reduced_motion = true;
          style = "compact";
          inline_height = 10;
          search_mode = "fuzzy";
          filter_mode_shell_up_key_binding = "session";
          session_path = config.sops.secrets.${sessionName}.path;
          key_path = config.sops.secrets.${keyName}.path;
        }
        // lib.optionalAttrs (osConfig != null && osConfig ? my.defaults.domain) {
          sync_address = "https://atuin.${osConfig.my.defaults.domain}";
        };
    };
  };
}
