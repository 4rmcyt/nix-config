# /etc/nixos/services/tg-notify.nix
{ config, pkgs, lib,... }:

let
  cfg = config.services.tg-notify;
in
{
  options.services.tg-notify = {
    enable = lib.mkEnableOption "Enable tg-notify script";
    botTokenFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to a file containing the Telegram bot token.";
    };
    chatIdFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to a file containing the destination chat ID.";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.telegram_bot_token = { };
    sops.secrets.telegram_chat_id = { };

    # FIX: Complete the systemPackages definition
    environment.systemPackages = with pkgs; [
      (pkgs.writeShellScriptBin "tg-notify" ''
        #!/bin/bash
        BOT_TOKEN=$(cat ${config.sops.secrets.telegram_bot_token.path})
        CHAT_ID=$(cat ${config.sops.secrets.telegram_chat_id.path})
        MESSAGE="$1"
        
        curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
          -d chat_id="$CHAT_ID" \
          -d text="$MESSAGE"
      '')
    ];
  };
}