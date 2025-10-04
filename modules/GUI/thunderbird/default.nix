{ config, ... }:
{
  accounts.email.accounts = {
    "redacted@example.com" = {
      address = "redacted@example.com";
      userName = "redacted@example.com";
      realName = "Redacted Name";
      primary = true;
      imap.host = "imap.gmail.com";
      imap.port = 993;
      imap.tls.enable = true;
      aerc.imapAuth = "xoauth2";
      thunderbird-extra = {
        enable = true;
        profiles = [ "${config.home.username}" ];
      };
    };
    "redacted@example.com" = {
      address = "redacted@example.com";
      userName = "redacted@example.com";
      realName = "Redacted Name";
      primary = true;
      imap.host = "imap.gmail.com";
      imap.port = 993;
      imap.tls.enable = true;
      aerc.imapAuth = "xoauth2";
      thunderbird-extra = {
        enable = true;
        profiles = [ "${config.home.username}" ];
      };
    };
    "redacted@example.com" = {
      address = "redacted@example.com";
      userName = "redacted@example.com";
      realName = "Redacted Name";
      primary = true;
      imap.host = "imap.gmail.com";
      imap.port = 993;
      imap.tls.enable = true;
      aerc.imapAuth = "xoauth2";
      thunderbird-extra = {
        enable = true;
        profiles = [ "${config.home.username}" ];
      };
    };
    "hayatzeevibbuk@gmail.com" = {
      address = "hayatzeevibbuk@gmail.com";
      userName = "hayatzeevibbuk@gmail.com";
      realName = "Redacted Name";
      primary = true;
      imap.host = "imap.gmail.com";
      imap.port = 993;
      imap.tls.enable = true;
      aerc.imapAuth = "xoauth2";
      thunderbird-extra = {
        enable = true;
        profiles = [ "${config.home.username}" ];
      };
    };
    "redacted@example.com" = {
      address = "redacted@example.com";
      userName = "redacted@example.com";
      realName = "Redacted Name";
      imap.host = "127.0.0.1";
      imap.port = 1143;
      imap.tls.useStartTls = true;
      smtp.host = "127.0.0.1";
      smtp.port = 1025;
      thunderbird-extra = {
        enable = true;
        profiles = [ "${config.home.username}" ];
      };
    };
  };

  programs.thunderbird = {
    enable = true;
    profiles.personal = {
      isDefault = true;
      withExternalGnupg = true;

      settings = {
        "mail.identity.default.archive_enabled" = true;
        "mail.identity.default.archive_keep_folder_structure" = true;
        "mail.identity.default.compose_html" = false;
        "mail.identity.default.protectSubject" = true;
        "mail.identity.default.reply_on_top" = 1;
        "mail.identity.default.sig_on_reply" = false;

        "gfx.webrender.all" = true;
        "gfx.webrender.enabled" = true;

        "browser.display.use_system_colors" = true;
        "browser.theme.dark-toolbar-theme" = true;
      };
    };

    settings = {
      # Some general settings.
      "mail.server.default.allow_utf8_accept" = true;
      "mail.server.default.max_articles" = 1000;
      "mail.server.default.check_all_folders_for_new" = true;
      "mail.show_headers" = 1;

      # Show some metadata.
      "mailnews.headers.showMessageId" = true;
      "mailnews.headers.showOrganization" = true;
      "mailnews.headers.showReferences" = true;
      "mailnews.headers.showUserAgent" = true;

      # Sort mails and news in descending order.
      "mailnews.default_sort_order" = 2;
      "mailnews.default_news_sort_order" = 2;
      # Sort mails and news by date.
      "mailnews.default_sort_type" = 18;
      "mailnews.default_news_sort_type" = 18;

      # Sort them by the newest reply in thread.
      "mailnews.sort_threads_by_root" = true;
      # Show time.
      "mail.ui.display.dateformat.default" = 1;
      # Sanitize it to UTC to prevent leaking local time.
      "mail.sanitize_date_header" = true;

      # Email composing QoL.
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

  home.persistence."/state".directories = [
    ".cache/thunderbird"
  ];

  home.persistence."/persist".directories = [
    ".thunderbird"
  ];
}
