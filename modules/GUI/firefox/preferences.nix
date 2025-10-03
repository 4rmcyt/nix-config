{
  programs.firefox.policies.Preferences = {
    # About Config & Warnings
    "browser.aboutConfig.showWarning" = false; # I sometimes know what I'm doing
    "browser.uitour.enabled" = false;
    "browser.warnOnQuitShortcut" = false;

    # Accessibility & Sound
    "accessibility.typeaheadfind.enablesound" = false; # Why the fuck can my search window make bell sounds
    "general.autoScroll" = true;

    # Content Blocking & Privacy
    "browser.send_pings" = false;
    "privacy.clearOnShutdown.history" = false; # We want to save history on exit
    "privacy.donottrackheader.enabled" = true;
    "privacy.trackingprotection.enabled" = true;
    "privacy.trackingprotection.socialtracking.enabled" = true;
    "privacy.userContext.enabled" = true;
    "privacy.userContext.ui.enabled" = true;

    # Data Reporting & Telemetry
    "app.normandy.enabled" = false;
    "app.shield.optoutstudies.enabled" = false;
    "browser.ping-centre.telemetry" = false;
    "browser.tabs.crashReporting.sendReport" = false; # Disable browser crash reporting
    "browser.urlbar.eventTelemetry.enabled" = false;
    "datareporting.healthreport.uploadEnabled" = false;
    "datareporting.policy.dataSubmissionEnabled" = false;
    "toolkit.telemetry.archive.enabled" = false;
    "toolkit.telemetry.enabled" = false;
    "toolkit.telemetry.server" = "";
    "toolkit.telemetry.unified" = false;

    # Developer Tools
    "devtools.chrome.enabled" = false; # Allow executing JS in the dev console
    "svg.context-properties.content.enabled" = true;
    "toolkit.legacyUserProfileCustomizations.stylesheets" = true; # Allow userChrome.css

    # Display & Hi-DPI
    "layout.css.devPixelsPerPx" = "1.5"; # Hi-DPI

    # DOM & Web Features
    "dom.battery.enabled" = false;
    "dom.private-attribution.submission.enabled" = true;
    "dom.push.connection.enabled" = true;
    "dom.push.enabled" = true;

    # Downloads
    "browser.download.useDownloadDir" = false; # Ask where to save stuff

    # Extensions
    "extensions.abuseReport.enabled" = false;
    "extensions.autoDisableScopes" = 0;
    "extensions.formautofill.creditCards.enabled" = true;
    "extensions.pocket.enabled" = false;
    "extensions.update.enabled" = true;
    "extensions.webcompat-reporter.enabled" = false;
    "extensions.webextensions.ExtensionStorageIDB.enabled" = false; # Make home-manager extension config work

    # Firefox Accounts & Services
    "browser.contentblocking.report.lockwise.enabled" = true;
    "identity.fxaccounts.commands.enabled" = true;
    "identity.fxaccounts.enabled" = true;
    "identity.fxaccounts.pairing.enabled" = true;
    "identity.fxaccounts.toolbar.enabled" = true;

    # Graphics & Hardware Acceleration
    "gfx.wayland.hdr" = true;
    "gfx.webrender.all" = true;
    "gfx.webrender.compositor.force-enabled" = true; # FIXME: enabling causes graphic glitches
    "gfx.x11-egl.force-enabled" = true;
    "image.avif.enabled" = true;
    "image.jxl.enabled" = true;
    "layers.acceleration.force-enabled" = true;
    "media.av1.enabled" = true;
    "media.cdpeg.vaapi.enabled" = true;
    "media.eme.enabled" = true;
    "media.ffmpeg.vaapi.enabled" = true;
    "media.ffvpx.enabled" = false;
    "media.hardware-video-decoding.force-enabled" = true;
    "media.hevc.enabled" = true;
    "media.hls.enabled" = true;
    "media.rdd-ffmpeg.enabled" = true;
    "media.rdd-vpx.enabled" = false;
    "media.videocontrols.picture-in-picture.enabled" = false;
    "widget.dmabuf.force-enabled" = true;

    # Internationalization
    "browser.translations.neverTranslateLanguages" = "ru,ua,he"; # No need :)
    "intl.accept_languages" = "en-US,en";

    # Network & Performance
    "browser.cache.disk.enable" = false;
    "browser.cache.memory.enable" = true;
    "browser.urlbar.speculativeConnect.enabled" = true;
    "network.predictor.enabled" = true;

    # New Tab Page
    "browser.newtabpage.activity-stream.showSponsored" = false;
    "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;

    # Startup & Session
    "browser.ctrlTab.sortByRecentlyUsed" = false; # (default) Who wants that?
    "browser.startup.page" = 3; # Resume previous session on startup

    # Tabs
    "browser.tabs.closeTabByDblclick" = true;
    "browser.tabs.dragOverThresholdPercent" = 10;
    "browser.tabs.groups.dragOverThresholdPercent" = 10;
    "browser.tabs.loadInBackground" = true;
    "browser.tabs.tabMinWidth" = 75;

    # UI & Theme
    "browser.eme.ui.enabled" = true;
    "browser.in-content.dark-mode" = true;
    "ui.systemUsesDarkTheme" = true;
    "widget.use-xdg-desktop-portal.file-picker" = 1;

    # URL Bar
    "browser.urlbar.placeholderName" = "DuckDuckGo";
    "browser.urlbar.placeholderName.private" = "DuckDuckGo";
    "browser.urlbar.shortcuts.bookmarks" = false;
    "browser.urlbar.shortcuts.history" = false;
    "browser.urlbar.shortcuts.tabs" = false;
    "browser.urlbar.suggest.calculator" = true;
    "browser.urlbar.suggest.searches" = true;
    "browser.urlbar.trimHttps" = true;
    "browser.urlbar.unitConversion.enabled" = true;
  };
}
