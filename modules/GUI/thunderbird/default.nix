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
      smtp = {
        host = "smtp.gmail.com";
        port = 587;
        tls.useStartTls = true;
      };
      # GPG configuration - using your existing key
      gpg = {
        key = "D85B52C9288A138E";
        signByDefault = true;
        encryptByDefault = false;
      };
      thunderbird = {
        enable = true;
        profiles = ["${config.home.username}"];
      };
    };

    # ProtonMail account (via bridge) - Updated for certificate handling
    "redacted@example.com" = {
      address = "redacted@example.com";
      userName = "redacted@example.com";
      realName = "Redacted Name";
      imap = {
        host = "127.0.0.1";
        port = 1143;
        tls = {
          enable = true;
          useStartTls = true;
        };
      };
      smtp = {
        host = "127.0.0.1";
        port = 1025;
        tls = {
          useStartTls = true;
        };
      };
      # GPG configuration - you'll need a separate key or subkey for this email
      gpg = {
        key = "redacted@example.com"; # Update with actual key ID
        signByDefault = true;
        encryptByDefault = false;
      };
      thunderbird = {
        enable = true;
        profiles = ["${config.home.username}"];
      };
    };

    # Secondary Gmail accounts (sorted alphabetically)
    "redacted@example.com" = {
      address = "redacted@example.com";
      userName = "redacted@example.com";
      realName = "Redacted Name";
      imap = {
        host = "imap.gmail.com";
        port = 993;
        tls.enable = true;
      };
      smtp = {
        host = "smtp.gmail.com";
        port = 587;
        tls.useStartTls = true;
      };
      # GPG configuration - you'll need a key for this email
      gpg = {
        key = "redacted@example.com"; # Update with actual key ID
        signByDefault = true;
        encryptByDefault = false;
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
      smtp = {
        host = "smtp.gmail.com";
        port = 587;
        tls.useStartTls = true;
      };
      # GPG configuration - you'll need a key for this email
      gpg = {
        key = "hayatzeevibbuk@gmail.com"; # Update with actual key ID
        signByDefault = true;
        encryptByDefault = false;
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
      smtp = {
        host = "smtp.gmail.com";
        port = 587;
        tls.useStartTls = true;
      };
      # GPG configuration - you'll need a key for this email
      gpg = {
        key = "redacted@example.com"; # Update with actual key ID
        signByDefault = true;
        encryptByDefault = false;
      };
      thunderbird = {
        enable = true;
        profiles = ["${config.home.username}"];
      };
    };
  };

  # =================================================================
  # 2. Thunderbird Application Configuration
  # =================================================================
  programs.thunderbird = {
    enable = true;

    profiles.${config.home.username} = {
      isDefault = true;
      withExternalGnupg = true;

      settings = {
        # Application settings
        "app.update.auto" = false;

        # Display and theme settings
        "browser.display.use_system_colors" = true;
        "browser.theme.dark-toolbar-theme" = true;

        # Graphics and rendering settings
        "gfx.webrender.all" = true;
        "gfx.webrender.enabled" = true;

        # Email composition settings
        "mail.identity.default.attachPgpKey" = true;
        "mail.identity.default.auto_quote" = true;
        "mail.identity.default.compose_html" = false;
        "mail.identity.default.protectSubject" = true;
        "mail.identity.default.reply_on_top" = 1;
        "mail.identity.default.sig_on_reply" = false;

        # Archive settings
        "mail.identity.default.archive_enabled" = true;
        "mail.identity.default.archive_keep_folder_structure" = true;

        # Server and connection settings
        "mail.server.default.allow_utf8_accept" = true;
        "mail.server.default.check_all_folders_for_new" = true;
        "mail.server.default.max_articles" = 1000;

        # Message display settings
        "mail.sanitize_date_header" = true;
        "mail.show_headers" = 1;
        "mail.ui.display.dateformat.default" = 1;

        # Header display settings
        "mailnews.headers.showMessageId" = true;
        "mailnews.headers.showOrganization" = true;
        "mailnews.headers.showReferences" = true;
        "mailnews.headers.showUserAgent" = true;

        # Sorting and threading settings
        "mailnews.default_news_sort_order" = 2; # Descending
        "mailnews.default_news_sort_type" = 18; # By date
        "mailnews.default_sort_order" = 2; # Descending
        "mailnews.default_sort_type" = 18; # By date
        "mailnews.sort_threads_by_root" = true;

        # Privacy settings
        "privacy.donottrackheader.enabled" = true;

        # OpenPGP/GPG settings (using external GPG)
        "mail.openpgp.allow_external_gnupg" = true;
        "mail.openpgp.alternative_gpg_path" = "${pkgs.gnupg}/bin/gpg";
        "mail.identity.default.sign_mail" = true;
        "mail.identity.default.encrypt_mail" = false;
        "mail.identity.default.encrypt_subject" = true;
        "mail.identity.default.attach_pgp_key" = true;
        "mail.openpgp.autoDecrypt" = true;
        "mail.openpgp.remind_encryption_possible" = true;
        "mail.openpgp.warn_unencrypted_reply" = true;

        # Certificate handling for ProtonMail Bridge
        "security.tls.insecure_fallback_hosts" = "127.0.0.1";
        "security.tls.accept_insecure_hosts" = "127.0.0.1";

        # OAuth2 Authentication for Gmail accounts
        "mail.server.server_redacted@example.com.authMethod" = 10; # OAuth2
        "mail.smtpserver.smtp_redacted@example.com.authMethod" = 10; # OAuth2

        "mail.server.server_redacted@example.com.authMethod" = 10; # OAuth2
        "mail.smtpserver.smtp_redacted@example.com.authMethod" = 10; # OAuth2

        "mail.server.server_hayatzeevibbuk@gmail.com.authMethod" = 10; # OAuth2
        "mail.smtpserver.smtp_hayatzeevibbuk@gmail.com.authMethod" = 10; # OAuth2

        "mail.server.server_redacted@example.com.authMethod" = 10; # OAuth2
        "mail.smtpserver.smtp_redacted@example.com.authMethod" = 10; # OAuth2
      };
    };
  };

  # =================================================================
  # 3. ProtonMail Bridge Integration
  # =================================================================
  home.packages = with pkgs; [
    protonmail-bridge
    protonmail-bridge-gui
  ];

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
      Environment = "PROTONMAIL_BRIDGE_LOG_LEVEL=info";
    };
    Install = {
      WantedBy = ["default.target"];
    };
  };
}
