{
  programs.zen-browser.policies =
    let
      mkLockedAttrs = builtins.mapAttrs (
        _: value: {
          Value = value;
          Status = "locked";
        }
      );
    in
    {
      Preferences = mkLockedAttrs {
        # === ACCESSIBILITY ===
        "accessibility.typeaheadfind.enablesound" = false;
        "general.autoScroll" = true;

        # === APP SETTINGS ===
        "app.normandy.enabled" = false;
        "app.shield.optoutstudies.enabled" = false;

        # === APZ (ASYNC PAN-ZOOM) ===
        "apz.overscroll.enabled" = true;

        # === BROWSER BEHAVIOR ===
        "browser.aboutConfig.showWarning" = false;
        "browser.cache.disk.enable" = false;
        "browser.cache.memory.enable" = true;
        "browser.cache.memory.capacity" = 1048576; # 1GB memory cache for 64GB RAM
        "browser.cache.memory.max_entry_size" = 51200; # 50MB max entry
        "browser.contentblocking.category" = "strict";
        "browser.contentblocking.report.lockwise.enabled" = true;
        "browser.ctrlTab.sortByRecentlyUsed" = false;
        "browser.download.start_downloads_in_tmp_dir" = true;
        "browser.download.useDownloadDir" = false;
        "browser.newtabpage.activity-stream.feeds.topsites" = false;
        "browser.newtabpage.activity-stream.showSponsored" = false;
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
        "browser.ping-centre.telemetry" = false;
        "browser.privatebrowsing.resetPBM.enabled" = true;
        "browser.safebrowsing.downloads.remote.enabled" = false;
        "browser.search.update" = false;
        "browser.send_pings" = false;
        "browser.sessionstore.interval" = 30000; # More frequent saves with your RAM
        "browser.startup.page" = 3; # Resume previous session
        "browser.tabs.crashReporting.sendReport" = false;
        "browser.tabs.hoverPreview.enabled" = true;
        "browser.tabs.loadInBackground" = true;
        "browser.tabs.warnOnClose" = false;
        "browser.topsites.contile.enabled" = false;
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
        "dom.ipc.processPriorityManager.backgroundUsesEcoQoS" = true;

        # === EDITOR ===
        "editor.truncate_user_pastes" = false;

        # === EXTENSIONS ===
        "extensions.abuseReport.enabled" = false;
        "extensions.autoDisableScopes" = 0;
        "extensions.formautofill.creditCards.enabled" = true;
        "extensions.update.enabled" = true;
        "extensions.webcompat-reporter.enabled" = false;
        "extensions.webextensions.ExtensionStorageIDB.enabled" = false;

        # === GEOLOCATION ===
        "geo.provider.network.url" = "https://beacondb.net/v1/geolocate";

        # === GRAPHICS & WEBRENDER (High-End NVIDIA System) ===
        "gfx.canvas.accelerated" = true;
        "gfx.canvas.accelerated.cache-size" = 1024; # 1GB cache for 64GB RAM
        "gfx.wayland.hdr" = false; # Enable HDR with high-end setup
        "gfx.webrender.all" = true;
        "gfx.webrender.compositor" = true;
        "gfx.webrender.compositor.force-enabled" = true;
        "gfx.webrender.enabled" = true;
        "gfx.x11-egl.force-enabled" = true;

        # === FIREFOX SYNC / IDENTITY ===
        "identity.fxaccounts.commands.enabled" = true;
        "identity.fxaccounts.enabled" = true;
        "identity.fxaccounts.pairing.enabled" = true;
        "identity.fxaccounts.toolbar.enabled" = true;

        # === IMAGES ===
        "image.avif.enabled" = true;
        "image.jxl.enabled" = true;

        # === INTERNATIONALIZATION ===
        "browser.translations.neverTranslateLanguages" = "ru,ua,he";
        "intl.accept_languages" = "en-US,en";

        # === LAYERS (GPU ACCELERATION) ===
        "layers.acceleration.force-enabled" = true;
        "layers.gpu-process.enabled" = true;
        "layers.gpu-process.force-enabled" = true;

        # === MEDIA & HARDWARE VIDEO ACCELERATION ===
        "browser.eme.ui.enabled" = true;
        "media.av1.enabled" = true;
        "media.av1.use-dav1d" = false; # Use hardware decoder
        "media.eme.enabled" = true;
        "media.ffmpeg.vaapi.enabled" = true;
        "media.ffvpx.enabled" = false; # Use system FFmpeg
        "media.hardware-video-decoding.enabled" = true;
        "media.hardware-video-decoding.force-enabled" = true;
        "media.hevc.enabled" = true;
        "media.hls.enabled" = true;
        "media.navigator.mediadatadecoder_vpx_enabled" = true;
        "media.rdd-ffmpeg.enabled" = true;
        "media.rdd-vpx.enabled" = false; # Disable VP8/VP9 in RDD process
        "media.videocontrols.picture-in-picture.video-toggle.enabled" = true;
        "media.wmf.amd.hevc.enabled" = true;
        "media.wmf.hevc.enabled" = true;

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
        "mousewheel.default.delta_multiplier_y" = 200;
        "mousewheel.min_line_scroll_amount" = 10;

        # === NETWORK ===
        "network.auth.subresource-http-auth-allow" = 1;
        "network.cookie.cookieBehavior" = 5;
        "network.dns.disablePrefetch" = false; # Enable with 64GB RAM
        "network.dns.disablePrefetchFromHTTPS" = false; # Enable with 64GB RAM
        "network.http.http3.enabled" = true;
        "network.http.pacing.requests.enabled" = true;
        "network.http.referer.XOriginTrimmingPolicy" = 2;
        "network.predictor.enable-prefetch" = true; # Enable with 64GB RAM
        "network.predictor.enabled" = true; # Enable with 64GB RAM
        "network.prefetch-next" = true; # Enable with 64GB RAM

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

        # === SECURITY ===
        "security.OCSP.enabled" = 0;
        "security.pki.crlite_mode" = 2;

        # === SIGN-ON ===
        "signon.formlessCapture.enabled" = false;
        "signon.privateBrowsingCapture.enabled" = false;

        # === SVG ===
        "svg.context-properties.content.enabled" = true;

        # === TELEMETRY ===
        "toolkit.telemetry.archive.enabled" = false;
        "toolkit.telemetry.enabled" = false;
        "toolkit.telemetry.server" = "";
        "toolkit.telemetry.unified" = false;

        # === TOOLKIT ===
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

        # === WEBGL ===
        "webgl.disabled" = false;
        "webgl.force-enabled" = true;
        "webgl.msaa-force" = true; # Enable MSAA with your GPU power

        # === WIDGET (WAYLAND/X11) ===
        "widget.dmabuf.force-enabled" = true; # Try enabling with your specs
        "widget.wayland.opaque-region.enabled" = false;
      };
    };
}
