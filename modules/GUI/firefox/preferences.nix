_: {
  programs.firefox.profiles.default.settings = {
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
    "browser.cache.frecency_half_life_hours" = 18; # More aggressive cache eviction
    "browser.cache.memory.capacity" = 10737418240; # 10GB memory cache for 64GB RAM
    "browser.cache.memory.max_entry_size" = 327680; # 50MB max entry
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
    "browser.sessionstore.interval" = 600000; # More frequent saves with your RAM
    "browser.sessionhistory.max_entries" = 5; # Reduce memory usage
    "browser.startup.page" = 3; # Resume previous session
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
    "dom.ipc.processPriorityManager.backgroundUsesEcoQoS" = true;
    "dom.private-attribution.submission.enabled" = false;
    "dom.webgpu.enabled" = true;

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
    "gfx.canvas.accelerated" = true;
    "gfx.canvas.accelerated.cache-items" = 32768;
    "gfx.canvas.remote" = false;
    "gfx.vsync.hw-vsync.enabled" = true;
    "gfx.webrender.all" = true;
    "gfx.webrender.compositor" = false;
    "gfx.webrender.compositor.force-enabled" = false;
    "gfx.webrender.enabled" = true;
    "gfx.webrender.force-disabled" = false;
    "gfx.webrender.software" = false;
    "gfx.webrender.software.opengl" = false;
    "gfx.webrender.precache-shaders" = true;
    "image.cache.size" = 10485760; # 10GB image cache for 64GB RAM
    "media.memory_caches_combined_limit_kb" = 3145728; # 3GB combined cache

    # === IMAGES ===
    "image.avif.enabled" = true;
    "image.jxl.enabled" = true;

    # === IDENTITY & SYNC ===
    "identity.fxaccounts.commands.enabled" = true;
    "identity.fxaccounts.enabled" = true;
    "identity.fxaccounts.pairing.enabled" = true;
    "identity.fxaccounts.toolbar.enabled" = true;

    # === INTERNATIONALIZATION ===
    "intl.accept_languages" = "en-US,en";

    # === LAYERS (GPU ACCELERATION) ===
    "layers.acceleration.disabled" = false;
    "layers.acceleration.force-enabled" = true;
    "layers.gpu-process.enabled" = true;
    "layers.gpu-process.force-enabled" = true;
    "layers.mlgpu.enabled" = true;
    "layers.omtp.enabled" = false;

    # === MEDIA & HARDWARE VIDEO ACCELERATION ===
    "media.av1.enabled" = true;
    "media.av1.use-dav1d" = false; # Use hardware decoder
    "media.cdpeg.vaapi.enabled" = true;
    "media.eme.enabled" = true;
    "media.ffmpeg.vaapi.enabled" = true;
    "media.ffmpeg.vaapi-drm-display.enabled" = true;
    "media.ffvpx.enabled" = false; # Use system FFmpeg
    "media.gpu-process-decoder" = true;
    "media.hardwaremediakeys.enabled" = false;
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
    "mousewheel.default.delta_multiplier_y" = 300;
    "mousewheel.min_line_scroll_amount" = 10;

    # === NETWORK ===
    "network.auth.subresource-http-auth-allow" = 1;
    "network.cookie.cookieBehavior" = 5;
    "network.http.http3.enabled" = true;
    "network.http.referer.XOriginTrimmingPolicy" = 2;
    "network.prefetch-next" = false;
    "network.dnsCacheEntries" = 20000;
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

    # === WAYLAND SETTINGS ===
    "widget.dmabuf.force-enabled" = true;
    "widget.gtk.wayland.force-enabled" = true;
    "widget.gtk.wayland.fractional-scaling.enabled" = true;
    "widget.use-xdg-desktop-portal.file-picker" = 1;
    "widget.use-xdg-desktop-portal.location" = 1;
    "widget.use-xdg-desktop-portal.mime-handler" = 1;
    "widget.use-xdg-desktop-portal.open-uri" = 1;
    "widget.use-xdg-desktop-portal.settings" = 1;

    # === WEBGL ===
    "webgl.disabled" = false;
    "webgl.force-enabled" = true;
    "webgl.msaa-force" = false; # Enable MSAA with your GPU power

    "javascript.options.baselinejit.threshold" = 50;
    "javascript.options.ion.threshold" = 5000;
    "javascript.options.concurrent_multiprocess_gcs.cpu_divisor" = 8;
    "dom.timeout.throttling_delay" = 40;
    "dom.timeout.budget_throttling_max_delay" = 0;
  };
}
