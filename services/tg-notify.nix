{ config, lib, pkgs, ... }:

let
  # Define cfg at the top-level let binding so it's accessible to the module's config
  # cfg now refers to config.services.tg-notify
  cfg = config.services.tg-notify;

  # The telegramCredentialsFile let binding is removed from here.
  # The path to the credentials file will now come from cfg.credentialsFile.

  # Define the tg-notify script as a shell script binary.
  # This script now expects BOT_TOKEN and CHAT_ID to be set as environment variables.
  tg-notify = pkgs.writeShellScriptBin "tg-notify" ''
    #!${pkgs.bash}/bin/bash

    # BOT_TOKEN and CHAT_ID are now provided via environment variables
    # by the systemd service's EnvironmentFile. No need to 'cat' them here.
    # Ensure these environment variables are set before the script runs.

    # Initialize positional arguments array
    POSITIONAL_ARGS=()

    # Parse command-line options
    while [[ $# -gt 0 ]]; do
      case $1 in
        -t)
          title="$2"
          shift # past argument
          shift # past value
          ;;
        -m)
          message="$2"
          shift # past argument
          shift # past value
          ;;
        -*|--*)
          echo "Unknown option $1"
          exit 1
          ;;
        *)
          POSITIONAL_ARGS+=("$1") # save positional arg
          shift # past argument
          ;;
      esac
    done

    # Define error messages to look for in logs/messages
    declare -a error_messages=(
      "Permanent errors have been detected"
      "UNAVAIL"
      "devices are faulted"
      "DEGRADED"
      "unrecoverable error"
    )

    # Reset positional arguments (if any were passed without flags)
    set -- "''${POSITIONAL_ARGS[@]}"

    # Get hostname using the explicitly path'd hostnamectl
    hostname=$(${pkgs.systemd}/bin/hostnamectl hostname)

    # Determine final title and message based on input
    if [[ "$title" =~ "service" ]]; then
      # If title contains "service", assume it's a service failure and fetch journal logs
      final_title="❌ Service $title failed on $hostname"
      # Fetch last 20 lines of journal for the specified service
      final_message=$(${pkgs.systemd}/bin/journalctl --unit="$title" -n 20 --no-pager)
    else
      # Otherwise, use the provided message and check for error keywords
      emoji="✅"
      for i in "''${error_messages[@]}"; do
        if [[ "$message" == *"$i"* ]]; then
          emoji="❌"
        fi
      done
      final_title="$emoji $title on $hostname"
      final_message="$message"
    fi

    # Construct the Telegram message text with HTML formatting
    text="
    <b>$final_title</b>

    <code>$final_message</code>
    "
    
    # Send the Telegram message using explicitly path'd curl.
    # BOT_TOKEN and CHAT_ID are now environment variables.
    ${pkgs.curl}/bin/curl --data "chat_id=$CHAT_ID" \
      --data-urlencode "text=$text" \
      --data-urlencode "parse_mode=HTML" \
      "https://api.telegram.org/bot$BOT_TOKEN/sendMessage"
  '';
in
{
  # Define module options under the 'services' namespace
  options.services.tg-notify = {
    enable = lib.mkEnableOption "Send system notifications via Telegram";
    
    # Re-introducing credentialsFile option, similar to the GitHub example
    credentialsFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Path to a file containing Telegram API_KEY and CHANNEL_ID
        as environment variables (e.g., "API_KEY=yourtoken\nCHANNEL_ID=yourid").
        This file should be managed by sops-nix for security.
      '';
      example = lib.literalExpression ''
        pkgs.writeText "telegram-credentials" '''
          API_KEY=secret_bot_token
          CHANNEL_ID=secret_chat_id
        '''
      '';
    };
  };

  # Configure the module based on options, also under the 'services' namespace
  config = lib.mkIf cfg.enable {
    # sops.secrets are now expected to be defined outside this module,
    # typically in configuration.nix or a dedicated sops module.
    # Removed: sops.secrets.telegram_bot_token = { };
    # Removed: sops.secrets.telegram_chat_id = { };

    # Make the tg-notify script available in the system's PATH
    environment.systemPackages = [ tg-notify ];

    # The tmpfiles rule for the credentials file is now managed where
    # cfg.credentialsFile is defined (e.g., in configuration.nix).
    # Removed: systemd.tmpfiles.rules = [ "f ${telegramCredentialsFile} 0640 root root -" ];

    # Define the services block for tg-notify
    services.tg-notify = { # This block correctly defines options specific to services.tg-notify
      # Define a templated systemd service for Telegram notifications
      systemd.services."tg-notify@" = {
        description = "Send a Telegram notification on service failure";
        after = [ "network.target" ]; # Ensure network is up before attempting to send

        serviceConfig = {
          Type = "oneshot"; # Service runs once and exits
          # ExecStart command uses the tg-notify script with the service name as title
          # %i is the instance name (e.g., "my-service" if you use tg-notify@my-service)
          ExecStart = "${lib.getExe tg-notify} -t %i";
          # Use EnvironmentFile to load BOT_TOKEN and CHAT_ID into the service's environment
          EnvironmentFile = cfg.credentialsFile; # Now uses the option
          # Add necessary packages to the service's PATH
          Path = with pkgs; [ systemd curl ];
        };
      };
    };
  };
}
