{
  programs.firefox.profiles.default.settings = {
    # === PERFORMANCE & HARDWARE ===
    "gfx.wayland.hdr" = false;
    "gfx.webrender.all" = true;
    "gfx.webrender.compositor.force-enabled" = true;
    "gfx.x11-egl.force-enabled" = true;
    "layers.acceleration.force-enabled" = true;
    "widget.dmabuf.force-enabled" = true;
    # "gfx.font_rendering.ahem_antialias_none" = true;
    "gfx.font_rendering.fontconfig.max_generic_substitutions" = 127;

    # === MEDIA & CODECS ===
    "image.avif.enabled" = true;
    "image.jxl.enabled" = true;
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

    # === PRIVACY & SECURITY ===
    "browser.send_pings" = false;
    "dom.battery.enabled" = false;
    "dom.private-attribution.submission.enabled" = false; # Fixed: was true
    "privacy.clearOnShutdown.history" = false;
    "privacy.donottrackheader.enabled" = true;
    "privacy.trackingprotection.enabled" = true;
    "privacy.trackingprotection.socialtracking.enabled" = true;
    "privacy.userContext.enabled" = true;
    "privacy.userContext.ui.enabled" = true;

    # === TELEMETRY (COMPLETE DISABLE) ===
    "app.normandy.enabled" = false;
    "app.shield.optoutstudies.enabled" = false;
    "browser.ping-centre.telemetry" = false;
    "browser.tabs.crashReporting.sendReport" = false;
    "browser.urlbar.eventTelemetry.enabled" = false;
    "datareporting.healthreport.uploadEnabled" = false;
    "datareporting.policy.dataSubmissionEnabled" = false;
    "toolkit.telemetry.archive.enabled" = false;
    "toolkit.telemetry.enabled" = false;
    "toolkit.telemetry.server" = "";
    "toolkit.telemetry.unified" = false;

    # === UI & BEHAVIOR ===
    "browser.aboutConfig.showWarning" = false;
    "browser.uitour.enabled" = false;
    "browser.warnOnQuitShortcut" = false;
    "browser.download.useDownloadDir" = false;
    "browser.ctrlTab.sortByRecentlyUsed" = false;
    "browser.startup.page" = 3; # Resume previous session

    # === TABS ===
    "browser.tabs.closeTabByDblclick" = true;
    "browser.tabs.dragOverThresholdPercent" = 10;
    "browser.tabs.groups.dragOverThresholdPercent" = 10;
    "browser.tabs.loadInBackground" = true;
    "browser.tabs.tabMinWidth" = 75;

    # === URL BAR ===
    "browser.urlbar.shortcuts.bookmarks" = false;
    "browser.urlbar.shortcuts.history" = false;
    "browser.urlbar.shortcuts.tabs" = false;
    "browser.urlbar.suggest.calculator" = true;
    "browser.urlbar.suggest.searches" = true;
    "browser.urlbar.trimHttps" = true;
    "browser.urlbar.unitConversion.enabled" = true;

    # === THEME & APPEARANCE ===
    "browser.in-content.dark-mode" = true;
    "ui.systemUsesDarkTheme" = true;
    "widget.use-xdg-desktop-portal.file-picker" = 1;
    "layout.css.devPixelsPerPx" = "1.7"; # Hi-DPI

    # === ACCESSIBILITY ===
    "accessibility.typeaheadfind.enablesound" = false;
    "general.autoScroll" = true;

    # === EXTENSIONS ===
    "extensions.abuseReport.enabled" = false;
    "extensions.autoDisableScopes" = 0;
    "extensions.formautofill.creditCards.enabled" = true;
    "extensions.update.enabled" = true;
    "extensions.webcompat-reporter.enabled" = false;
    "extensions.webextensions.ExtensionStorageIDB.enabled" = false;

    # === FIREFOX SYNC ===
    "browser.contentblocking.report.lockwise.enabled" = true;
    "identity.fxaccounts.commands.enabled" = true;
    "identity.fxaccounts.enabled" = true;
    "identity.fxaccounts.pairing.enabled" = true;
    "identity.fxaccounts.toolbar.enabled" = true;

    # === NETWORK & PERFORMANCE ===
    "browser.cache.disk.enable" = false;
    "browser.cache.memory.enable" = true;

    # === NEW TAB PAGE ===
    "browser.newtabpage.activity-stream.showSponsored" = false;
    "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;

    # === DEVELOPER TOOLS ===
    "devtools.chrome.enabled" = false;
    "svg.context-properties.content.enabled" = true;
    "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

    # === SMOOTH SCROLLING ===
    "apz.overscroll.enabled" = true;
    "general.smoothScroll" = true;
    "general.smoothScroll.currentVelocityWeighting" = 0.15;
    "general.smoothScroll.mouseWheel.durationMinMS" = 80;
    "general.smoothScroll.msdPhysics.enabled" = false;
    "general.smoothScroll.stopDecelerationWeighting" = 0.6;
    "mousewheel.default.delta_multiplier_y" = 300;
    "mousewheel.min_line_scroll_amount" = 10;

    # === INTERNATIONALIZATION ===
    "browser.translations.neverTranslateLanguages" = "ru,ua,he";
    "intl.accept_languages" = "en-US,en";

    # === DOM & PUSH ===
    "dom.push.connection.enabled" = true;
    "dom.push.enabled" = true;

    # === MISC ===
    "browser.eme.ui.enabled" = true;
  };
}
