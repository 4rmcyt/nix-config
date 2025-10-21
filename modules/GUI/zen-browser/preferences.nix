_: {
  programs.zen-browser.profiles.default.settings = {
    # === BROWSER BEHAVIOR ===
    "browser.aboutConfig.showWarning" = false;
    "browser.cache.disk.enable" = false;
    "browser.cache.memory.enable" = true;
    "browser.contentblocking.category" = "strict";
    "browser.contentblocking.report.lockwise.enabled" = true;
    "browser.ctrlTab.sortByRecentlyUsed" = false;
    "browser.download.start_downloads_in_tmp_dir" = true;
    "browser.download.useDownloadDir" = false;
    "browser.eme.ui.enabled" = true;
    "browser.newtabpage.activity-stream.feeds.topsites" = false;
    "browser.newtabpage.activity-stream.showSponsored" = false;
    "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
    "browser.ping-centre.telemetry" = false;
    "browser.privatebrowsing.resetPBM.enabled" = true;
    "browser.safebrowsing.downloads.remote.enabled" = false;
    "browser.search.update" = false;
    "browser.send_pings" = false;
    "browser.tabs.crashReporting.sendReport" = false;
    "browser.tabs.hoverPreview.enabled" = true;
    "browser.tabs.loadInBackground" = true;
    "browser.tabs.warnOnClose" = false;
    "browser.topsites.contile.enabled" = false;
    "browser.translations.neverTranslateLanguages" = "ru,ua,he";
    "browser.uitour.enabled" = false;
    "browser.urlbar.eventTelemetry.enabled" = false;
    "browser.urlbar.quicksuggest.enabled" = false;
    "browser.urlbar.shortcuts.bookmarks" = false;
    "browser.urlbar.shortcuts.history" = false;
    "browser.urlbar.shortcuts.tabs" = false;
    "browser.urlbar.suggest.calculator" = true;
    "browser.urlbar.suggest.searches" = true;
    "browser.urlbar.trimHttps" = true;
    "browser.urlbar.unitConversion.enabled" = true;
    "browser.warnOnQuitShortcut" = false;

    # === DATA REPORTING ===
    "datareporting.healthreport.uploadEnabled" = false;
    "datareporting.policy.dataSubmissionEnabled" = false;

    # === DEVELOPER TOOLS ===
    "devtools.chrome.enabled" = false;

    # === DOM ===
    "dom.battery.enabled" = false;

    # === EDITOR ===
    "editor.truncate_user_pastes" = false;

    # === EXTENSIONS ===
    "extensions.abuseReport.enabled" = false;
    "extensions.autoDisableScopes" = 0;
    "extensions.formautofill.creditCards.enabled" = true;
    "extensions.update.enabled" = true;
    "extensions.webcompat-reporter.enabled" = false;
    "extensions.webextensions.ExtensionStorageIDB.enabled" = false;
    "extensions.pocket.enabled" = false;

    # === GEOLOCATION ===
    "geo.provider.network.url" = "https://beacondb.net/v1/geolocate";

    # === GRAPHICS & CANVAS ===
    "gfx.webrender.all" = true;

    # === IDENTITY & SYNC ===
    "identity.fxaccounts.commands.enabled" = true;
    "identity.fxaccounts.enabled" = true;
    "identity.fxaccounts.pairing.enabled" = true;
    "identity.fxaccounts.toolbar.enabled" = true;

    # === INTERNATIONALIZATION ===
    "intl.accept_languages" = "en-US,en";

    # === MEDIA & HARDWARE VIDEO ACCELERATION ===
    "media.av1.enabled" = true;
    "media.eme.enabled" = true;
    "media.ffmpeg.vaapi.enabled" = true;
    "media.hardware-video-decoding.enabled" = true;
    "media.hevc.enabled" = true;
    "media.hls.enabled" = true;

    # === MOUSE & SCROLLING ===
    "general.smoothScroll" = true;
    "general.smoothScroll.currentVelocityWeighting" = 0.15;
    "general.smoothScroll.mouseWheel.durationMinMS" = 80;
    "general.smoothScroll.msdPhysics.continuousMotionMaxDeltaMS" = 12;
    "general.smoothScroll.msdPhysics.enabled" = false;
    "general.smoothScroll.msdPhysics.motionBeginSpringConstant" = 600;
    "general.smoothScroll.msdPhysics.regularSpringConstant" = 650;
    "general.smoothScroll.msdPhysics.slowdownMinDeltaMS" = 25;
    "general.smoothScroll.msdPhysics.slowdownSpringConstant" = 250;
    "general.smoothScroll.stopDecelerationWeighting" = 0.6;
    "mousewheel.default.delta_multiplier_y" = 300;
    "mousewheel.min_line_scroll_amount" = 10;

    # === NETWORK ===
    "network.auth.subresource-http-auth-allow" = 1;
    "network.cookie.cookieBehavior" = 5;
    "network.http.http3.enabled" = true;
    "network.http.referer.XOriginTrimmingPolicy" = 2;
    "network.prefetch-next" = false;
    "network.dnsCacheExpiration" = 3600; # 1 hour
    "network.dnsCacheExpirationGracePeriod" = 240; # 4 minutes
    "network.predictor.enable-hover-on-ssl" = true;
    "network.predictor.enable-prefetch" = true;
    "network.predictor.preconnect-min-confidence" = 20;
    "network.predictor.prefetch-force-valid-for" = 3600; # 1 hour
    "network.predictor.prefetch-min-confidence" = 30;
    "network.predictor.prefetch-rolling-load-count" = 120;
    "network.predictor.preresolve-min-confidence" = 10;
    "ssl_tokens_cache_capacity" = 10; # Cache 10 SSL session tokens
    "network.buffer.cache.size" = 65535; # 10GB buffer cache for 64GB RAM

    # === PERMISSIONS ===
    "permissions.default.desktop-notification" = 2;
    "permissions.default.geo" = 2;
    "permissions.manager.defaultsUrl" = "";

    # === PRIVACY & SECURITY ===
    "privacy.clearOnShutdown.history" = false;
    "privacy.donottrackheader.enabled" = true;
    "privacy.firstparty.isolate" = true;
    "privacy.history.custom" = true;
    "privacy.resistFingerprinting" = true;
    "privacy.trackingprotection.allow_list.baseline.enabled" = true;
    "privacy.trackingprotection.allow_list.convenience.enabled" = true;
    "privacy.trackingprotection.enabled" = true;
    "privacy.trackingprotection.socialtracking.enabled" = true;
    "privacy.userContext.enabled" = true;
    "privacy.userContext.ui.enabled" = true;

    # === SIGN-ON ===
    "signon.formlessCapture.enabled" = true;
    "signon.privateBrowsingCapture.enabled" = false;

    # === TELEMETRY ===
    "toolkit.telemetry.archive.enabled" = false;
    "toolkit.telemetry.enabled" = false;
    "toolkit.telemetry.server" = "";
    "toolkit.telemetry.unified" = false;

    # === TOOLKIT ===
    "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
  };
}
