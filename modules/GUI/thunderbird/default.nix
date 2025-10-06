{
  config,
  pkgs,
  ...
}: {
  # =================================================================
  # 1. Email Accounts Configuration
  # =================================================================
  accounts.email.accounts = {
    # Primary Gmail account
    "redacted@example.com" = {
      address = "redacted@example.com";
      userName = "redacted@example.com";
      realName = "Redacted Name";
      primary = true;
      imap = {
        host = "imap.gmail.com";
        port = 993;
        tls.enable = true;
      };
      thunderbird = {
        enable = true;
        profiles = ["${config.home.username}"];
      };
    };

    # Secondary Gmail accounts
    "redacted@example.com" = {
      address = "redacted@example.com";
      userName = "redacted@example.com";
      realName = "Redacted Name";
      imap = {
        host = "imap.gmail.com";
        port = 993;
        tls.enable = true;
      };
      thunderbird = {
        enable = true;
        profiles = ["${config.home.username}"];
      };
    };

    "hayatzeevibbuk@gmail.com" = {
      address = "hayatzeevibbuk@gmail.com";
      userName = "hayatzeevibbuk@gmail.com";
      realName = "Redacted Name";
      imap = {
        host = "imap.gmail.com";
        port = 993;
        tls.enable = true;
      };
      thunderbird = {
        enable = true;
        profiles = ["${config.home.username}"];
      };
    };

    "redacted@example.com" = {
      address = "redacted@example.com";
      userName = "redacted@example.com";
      realName = "Redacted Name";
      imap = {
        host = "imap.gmail.com";
        port = 993;
        tls.enable = true;
      };
      thunderbird = {
        enable = true;
        profiles = ["${config.home.username}"];
      };
    };

    # ProtonMail account (via bridge)
    "redacted@example.com" = {
      address = "redacted@example.com";
      userName = "redacted@example.com";
      realName = "Redacted Name";
      imap = {
        host = "127.0.0.1";
        port = 1143;
        tls.useStartTls = true;
      };
      smtp = {
        host = "127.0.0.1";
        port = 1025;
        tls.useStartTls = true;
      };
      thunderbird = {
        enable = true;
        profiles = ["${config.home.username}"];
      };
    };
  };

  # =================================================================
  # 2. Thunderbird Configuration
  # =================================================================
  programs.thunderbird = {
    enable = true;

    # Profile settings
    profiles.${config.home.username} = {
      isDefault = true;
      withExternalGnupg = true;

      settings = {
        # App update settings
        "app.update.auto" = false;

        # Theme settings
        "browser.display.use_system_colors" = true;
        "browser.theme.dark-toolbar-theme" = true;

        # Graphics settings
        "gfx.webrender.all" = true;
        "gfx.webrender.enabled" = true;

        # Date/time settings
        "mail.sanitize_date_header" = true;
        "mail.ui.display.dateformat.default" = 1;

        # Email composition settings
        "mail.identity.default.attachPgpKey" = true;
        "mail.identity.default.auto_quote" = true;

        # Identity settings
        "mail.identity.default.archive_enabled" = true;
        "mail.identity.default.archive_keep_folder_structure" = true;
        "mail.identity.default.compose_html" = false;
        "mail.identity.default.protectSubject" = true;
        "mail.identity.default.reply_on_top" = 1;
        "mail.identity.default.sig_on_reply" = false;

        # Server settings
        "mail.server.default.allow_utf8_accept" = true;
        "mail.server.default.check_all_folders_for_new" = true;
        "mail.server.default.max_articles" = 1000;
        "mail.show_headers" = 1;

        # Header display settings
        "mailnews.headers.showMessageId" = true;
        "mailnews.headers.showOrganization" = true;
        "mailnews.headers.showReferences" = true;
        "mailnews.headers.showUserAgent" = true;

        # Sorting settings
        "mailnews.default_sort_order" = 2; # Descending
        "mailnews.default_news_sort_order" = 2; # Descending
        "mailnews.default_sort_type" = 18; # By date
        "mailnews.default_news_sort_type" = 18; # By date
        "mailnews.sort_threads_by_root" = true;

        # Privacy settings
        "privacy.donottrackheader.enabled" = true;
      };
    };
  };

  # =================================================================
  # 3. ProtonMail Bridge
  # =================================================================
  home.packages = with pkgs; [
    protonmail-bridge
    protonmail-bridge-gui
  ];

  # ProtonMail Bridge service
  systemd.user.services.protonmailbridge = {
    Unit = {
      Description = "Start Proton Mail Bridge";
      PartOf = "graphical-session.target";
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.protonmail-bridge}/bin/protonmail-bridge --noninteractive";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install = {
      WantedBy = ["default.target"];
    };
  };
}
