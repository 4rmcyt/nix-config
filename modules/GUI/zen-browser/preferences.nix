{
  programs.zen-browser.policies = let
    mkLockedAttrs = builtins.mapAttrs (
      _: value: {
        Value = value;
        Status = "locked";
      }
    );
  in {
    Preferences = mkLockedAttrs {
      # === ACCESSIBILITY ===
      "accessibility.typeaheadfind.enablesound" = false;
      "general.autoScroll" = true;

      # === DEVELOPER TOOLS ===
      "devtools.chrome.enabled" = false;
      "svg.context-properties.content.enabled" = true;
      "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

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

      # === INTERNATIONALIZATION ===
      "browser.translations.neverTranslateLanguages" = "ru,ua,he";
      "intl.accept_languages" = "en-US,en";

      # === MEDIA & CODECS ===
      "browser.eme.ui.enabled" = true;
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
      "media.videocontrols.picture-in-picture.video-toggle.enabled" = true;

      # === NETWORK & PERFORMANCE ===
      "browser.cache.disk.enable" = false;
      "browser.cache.memory.enable" = true;
      "browser.download.start_downloads_in_tmp_dir" = true;
      "browser.safebrowsing.downloads.remote.enabled" = false;
      "dom.ipc.processPriorityManager.backgroundUsesEcoQoS" = true;
      "network.auth.subresource-http-auth-allow" = 1;
      "network.cookie.cookieBehavior" = 5;
      "network.dns.disablePrefetch" = true;
      "network.dns.disablePrefetchFromHTTPS" = true;
      "network.http.http3.enabled" = true;
      "network.http.pacing.requests.enabled" = true;
      "network.http.referer.XOriginTrimmingPolicy" = 2;
      "network.predictor.enable-prefetch" = false;
      "network.predictor.enabled" = false;
      "network.prefetch-next" = false;

      # === NEW TAB PAGE ===
      "browser.newtabpage.activity-stream.feeds.topsites" = false;
      "browser.newtabpage.activity-stream.showSponsored" = false;
      "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
      "browser.topsites.contile.enabled" = false;

      # === PERFORMANCE & HARDWARE ===
      "gfx.canvas.accelerated.cache-size" = 512;
      "gfx.wayland.hdr" = true;
      "gfx.webrender.all" = true;
      "gfx.x11-egl.force-enabled" = true;
      "layers.acceleration.force-enabled" = true;
      "widget.dmabuf.force-enabled" = true;

      # === PRIVACY & SECURITY ===
      "browser.contentblocking.category" = "strict";
      "browser.privatebrowsing.resetPBM.enabled" = true;
      "browser.search.update" = false;
      "browser.send_pings" = false;
      "browser.urlbar.quicksuggest.enabled" = false;
      "datareporting.healthreport.uploadEnabled" = false;
      "datareporting.policy.dataSubmissionEnabled" = false;
      "dom.battery.enabled" = false;
      "editor.truncate_user_pastes" = false;
      "geo.provider.network.url" = "https://beacondb.net/v1/geolocate";
      "permissions.default.desktop-notification" = 2;
      "permissions.default.geo" = 2;
      "permissions.manager.defaultsUrl" = "";
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
      "security.OCSP.enabled" = 0;
      "security.pki.crlite_mode" = 2;
      "signon.formlessCapture.enabled" = false;
      "signon.privateBrowsingCapture.enabled" = false;

      # === SMOOTH SCROLLING ===
      "apz.overscroll.enabled" = true;
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
      "mousewheel.default.delta_multiplier_y" = 200;
      "mousewheel.min_line_scroll_amount" = 10;

      # === TABS ===
      "browser.tabs.crashReporting.sendReport" = false;
      "browser.tabs.hoverPreview.enabled" = true;
      "browser.tabs.loadInBackground" = true;
      "browser.tabs.warnOnClose" = false;

      # === TELEMETRY (COMPLETE DISABLE) ===
      "app.normandy.enabled" = false;
      "app.shield.optoutstudies.enabled" = false;
      "browser.ping-centre.telemetry" = false;
      "browser.urlbar.eventTelemetry.enabled" = false;
      "toolkit.telemetry.archive.enabled" = false;
      "toolkit.telemetry.enabled" = false;
      "toolkit.telemetry.server" = "";
      "toolkit.telemetry.unified" = false;

      # === UI & BEHAVIOR ===
      "browser.aboutConfig.showWarning" = false;
      "browser.ctrlTab.sortByRecentlyUsed" = false;
      "browser.download.useDownloadDir" = false;
      "browser.sessionstore.interval" = 60000;
      "browser.startup.page" = 3; # Resume previous session
      "browser.uitour.enabled" = false;
      "browser.warnOnQuitShortcut" = false;

      # === URL BAR ===
      "browser.urlbar.shortcuts.bookmarks" = false;
      "browser.urlbar.shortcuts.history" = false;
      "browser.urlbar.shortcuts.tabs" = false;
      "browser.urlbar.suggest.calculator" = true;
      "browser.urlbar.suggest.searches" = true;
      "browser.urlbar.trimHttps" = true;
      "browser.urlbar.unitConversion.enabled" = true;
    };
  };
}
