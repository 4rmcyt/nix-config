{ pkgs, ... }:

{
  imports = [
    ./external/thunderbird.nix
  ];

  accounts.email.accounts = {
    "4rmcyt@gmail.com" = {
      address = "4rmcyt@gmail.com";
      userName = "4rmcyt@gmail.com";
      realName = "Volodymyr Kondratenko";
      primary = true;
      imap.host = "imap.gmail.com";
      imap.port = 993;
      imap.tls.enable = true;
      aerc.imapAuth = "xoauth2";
      thunderbird-extra = {
        enable = true;
        profiles = [ "default" ];
      };
    };
    "vld.kondratenk@gmail.com" = {
      address = "vld.kondratenk@gmail.com";
      userName = "vld.kondratenk@gmail.com";
      realName = "Volodymyr Kondratenko";
      primary = true;
      imap.host = "imap.gmail.com";
      imap.port = 993;
      imap.tls.enable = true;
      aerc.imapAuth = "xoauth2";
      thunderbird-extra = {
        enable = true;
        profiles = [ "default" ];
      };
    };
    "bakbukdibbuk@gmail.com" = {
      address = "bakbukdibbuk@gmail.com";
      userName = "bakbukdibbuk@gmail.com";
      realName = "Zeev Hayat";
      primary = true;
      imap.host = "imap.gmail.com";
      imap.port = 993;
      imap.tls.enable = true;
      aerc.imapAuth = "xoauth2";
      thunderbird-extra = {
        enable = true;
        profiles = [ "default" ];
      };
    };
    "hayatzeevibbuk@gmail.com" = {
      address = "hayatzeevibbuk@gmail.com";
      userName = "hayatzeevibbuk@gmail.com";
      realName = "Zeev Hayat";
      primary = true;
      imap.host = "imap.gmail.com";
      imap.port = 993;
      imap.tls.enable = true;
      aerc.imapAuth = "xoauth2";
      thunderbird-extra = {
        enable = true;
        profiles = [ "default" ];
      };
    };
    "bakbukdibbuk@protonmail.com" = {
      address = "bakbukdibbuk@protonmail.com";
      userName = "bakbukdibbuk@protonmail.com";
      realName = "Volodymyr Kondratenko";
      imap.host = "127.0.0.1";
      imap.port = 1143;
      imap.tls.useStartTls = true;
      smtp.host = "127.0.0.1";
      smtp.port = 1025;
      thunderbird-extra = {
        enable = true;
        profiles = [ "default" ];
      };
    };
  };

  # Thunderbird
  programs.thunderbird-extra = {
    enable = true;
    profiles = {
      "defaults" = {
        isDefault = true;
        absolutePath = "/home/zeev/.config/thunderbird/default";
      };
    };
  };

  # Proton Mail Bridge
  home.packages = with pkgs; [
    protonmail-bridge
  ];

  systemd.user.services.protonmail-bridge = {
    Unit = {
      Description = "Start Proton Mail Bridge";
      PartOf = "graphical-session.target";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      Environment = [
        "XDG_CONFIG_HOME=/home/marc/Services/protonmail-bridge/config"
        "XDG_CACHE_HOME=/home/marc/Services/protonmail-bridge/cache"
        "XDG_DATA_HOME=/home/marc/Services/protonmail-bridge/data"
      ];
      ExecStart = "${pkgs.protonmail-bridge}/bin/protonmail-bridge --noninteractive";
      Restart = "on-failure";
    };
  };
}