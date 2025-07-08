{ config, lib, pkgs, ... }:

let
  # Define the tg-notify script as a shell script binary
  tg-notify = pkgs.writeShellScriptBin "tg-notify" ''
    #!${pkgs.bash}/bin/bash

    # Retrieve BOT_TOKEN and CHAT_ID directly from sops secrets paths
    # Ensure 'cat' is explicitly path'd using pkgs.coreutils
    BOT_TOKEN="$(${pkgs.coreutils}/bin/cat ${config.sops.secrets.telegram_bot_token.path})"
    CHAT_ID="$(${pkgs.coreutils}/bin/cat ${config.sops.secrets.telegram_chat_id.path})"

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
    
    # Send the Telegram message using explicitly path'd curl
    ${pkgs.curl}/bin/curl --data "chat_id=$CHAT_ID" \
      --data-urlencode "text=$text" \
      --data-urlencode "parse_mode=HTML" \
      "https://api.telegram.org/bot$BOT_TOKEN/sendMessage"
  '';
in
{
  # Define sops secrets for bot token and chat ID
  sops.secrets.telegram_bot_token = { };
  sops.secrets.telegram_chat_id = { };

  # Define module options
  options.tg-notify = {
    enable = lib.mkEnableOption "Send system notifications via Telegram";
    # The credentialsFile option is removed as secrets are accessed directly
  };

  # Configure the module based on options
  config = lib.mkIf cfg.enable {
    # Define a templated systemd service for Telegram notifications
    systemd.services."tg-notify@" = {
      description = "Send a Telegram notification on service failure";
      after = [ "network.target" ]; # Ensure network is up before attempting to send

      serviceConfig = {
        Type = "oneshot"; # Service runs once and exits
        # ExecStart command uses the tg-notify script with the service name as title
        # %i is the instance name (e.g., "my-service" if you use tg-notify@my-service)
        ExecStart = "${lib.getExe tg-notify} -t %i";
        # EnvironmentFile is removed as secrets are accessed directly in the script
        # Add necessary packages to the service's PATH for commands not explicitly path'd
        Path = with pkgs; [ systemd curl coreutils ]; # Added coreutils for 'cat'
      };
    };

    # Make the tg-notify script available in the system's PATH
    environment.systemPackages = [ tg-notify ];
  };
}
