{ config, pkgs, ... }:

{
  sops.secrets.telegram_bot_token = { };
  sops.secrets.telegram_chat_id = { };

  # Create telegram notification script
  environment.systemPackages = [
    (pkgs.writeScriptBin "tg-notify" ''
      #!${pkgs.bash}/bin/bash
      
      BOT_TOKEN="$(cat ${config.sops.secrets.telegram_bot_token.path})"
      CHAT_ID="$(cat ${config.sops.secrets.telegram_chat_id.path})"
      MESSAGE="$1"
      
      if [ -z "$MESSAGE" ]; then
        echo "Usage: tg-notify 'message'"
        exit 1
      fi
      
      ${pkgs.curl}/bin/curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
        -d "chat_id=$CHAT_ID" \
        -d "text=$MESSAGE" \
        -d "parse_mode=HTML"
    '')
  ];
  
  # System notification service
  systemd.services.system-telegram-notify = {
    description = "System notifications via Telegram";
    after = [ "network.target" ];
    
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c 'tg-notify \"System started on $(hostname)\"'";
    };
  };
}