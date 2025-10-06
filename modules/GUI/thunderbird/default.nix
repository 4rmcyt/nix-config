{ config, ... }:
{
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
        profiles = [ "${config.home.username}" ];
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
        profiles = [ "${config.home.username}" ];
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
        profiles = [ "${config.home.username}" ];
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
        profiles = [ "${config.home.username}" ];
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
        profiles = [ "${config.home.username}" ];
      };
    };
  };

  # Thunderbird configuration
  programs.thunderbird = {
    enable = true;

    # Profile settings
    profiles.${config.home.username} = {
      isDefault = true;
      withExternalGnupg = true;

      settings = {
        # Identity settings
        "mail.identity.default.archive_enabled" = true;
        "mail.identity.default.archive_keep_folder_structure" = true;
        "mail.identity.default.compose_html" = false;
        "mail.identity.default.protectSubject" = true;
        "mail.identity.default.reply_on_top" = 1;
        "mail.identity.default.sig_on_reply" = false;

        # Graphics settings
        "gfx.webrender.all" = true;
        "gfx.webrender.enabled" = true;

        # Theme settings
        "browser.display.use_system_colors" = true;
        "browser.theme.dark-toolbar-theme" = true;

        # Server settings
        "mail.server.default.allow_utf8_accept" = true;
        "mail.server.default.max_articles" = 1000;
        "mail.server.default.check_all_folders_for_new" = true;
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

        # Date/time settings
        "mail.ui.display.dateformat.default" = 1;
        "mail.sanitize_date_header" = true;

        # Email composition settings
        "mail.identity.default.auto_quote" = true;
        "mail.identity.default.attachPgpKey" = true;

      "app.update.auto" = false;
      "privacy.donottrackheader.enabled" = true;
    };

    policies.ExtensionSettings."en-CA@dictionaries.addons.mozilla.org" = {
      installation_mode = "force_installed";
      install_url = "https://addons.thunderbird.net/thunderbird/downloads/latest/canadian-english-dictionary/latest.xpi";
    };
    policies.ExtensionSettings."uk-UA@dictionaries.addons.mozilla.org" = {
      installation_mode = "force_installed";
      install_url = "https://addons.thunderbird.net/thunderbird/downloads/latest/ukrainian-dictionary/latest.xpi";
    };
  };

  programs.thunderbird-extra = {
    enable = true;
    profiles = [ "${config.home.username}" ];
    settings = id: {
      "mail.server.server_${id}.authMethod" = 10;
      "mail.smtpserver.smtp_${id}.authMethod" = 10;
    };
  };

  # Proton Mail Bridge
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
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.protonmail-bridge}/bin/protonmail-bridge --noninteractive";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
