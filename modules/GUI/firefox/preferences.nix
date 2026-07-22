_: {
  programs.firefox.profiles.default.settings = {
    # === ACCESSIBILITY ===
    "accessibility.typeaheadfind.enablesound" = false;
    "general.autoScroll" = true;

    # === APP SETTINGS ===
    "app.normandy.enabled" = false;
    "app.normandy.api_url" = "";
    "app.shield.optoutstudies.enabled" = false;

    # === CRASH REPORTS ===
    "breakpad.reportURL" = "";

    # === AI FEATURES (DISABLED) ===
    "browser.ml.enable" = false; # Master switch for on-device ML/AI features
    "browser.ml.chat.enabled" = false; # AI chatbot sidebar
    "browser.ml.chat.sidebar" = false;
    "browser.ml.chat.menu" = false; # Remove "Ask a chatbot" from tab context menu
    "browser.ml.chat.page" = false; # Remove "Ask a chatbot" from page context menu
    "browser.ml.linkPreview.enabled" = false; # AI-generated link preview key points
    "browser.ml.pageAssist.enabled" = false;
    "browser.ml.smartAssist.enabled" = false;
    "extensions.ml.enabled" = false;
    "browser.tabs.groups.smart.enabled" = false; # AI-suggested tab group names
    "browser.tabs.groups.smart.userEnabled" = false;
    "pdfjs.enableAltTextModelDownload" = false; # AI-generated PDF alt text model
    "pdfjs.enableGuessAltText" = false;
    "pdfjs.enableScripting" = false; # Disable JS execution inside embedded PDFs
    "browser.ai.control.default" = "blocked"; # Unified AI-feature kill switch (FF152+)

    # === APZ (ASYNC PAN-ZOOM) ===
    "apz.overscroll.enabled" = true;

    # === BROWSER BEHAVIOR ===
    # Disable client-side decorations for COSMIC compatibility
    "browser.tabs.inTitlebar" = 0; # Use system titlebar with window controls
    "widget.gtk.non-native-titlebar-buttons.enabled" = true; # Enable native GTK window controls
    "layout.css.devPixelsPerPx" = "2.0"; # Default scaling
    "widget.gtk.libadwaita-colors.enabled" = false;
    "browser.aboutConfig.showWarning" = false;
    "browser.aboutwelcome.enabled" = false;
    "browser.discovery.enabled" = false;
    "browser.preferences.moreFromMozilla" = false;
    "browser.uidensity" = 1; # 0 = normal, 1 = compact, 2 = touch
    "content.notify.interval" = 100000; # FastFox: reduce main-thread reflow frequency
    "browser.cache.disk.enable" = false;
    "browser.cache.memory.enable" = true;
    "browser.cache.frecency_half_life_hours" = 18; # More aggressive cache eviction
    "browser.contentblocking.category" = "strict";
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
    "datareporting.usage.uploadEnabled" = false;

    # === DEVELOPER TOOLS ===
    "devtools.chrome.enabled" = true;

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
    "extensions.getAddons.cache.enabled" = false; # Stop fetching AMO recommendation metadata
    "extensions.update.enabled" = true;
    "extensions.webcompat-reporter.enabled" = false;
    "extensions.webextensions.ExtensionStorageIDB.enabled" = false;

    # === GEOLOCATION ===
    "geo.provider.network.url" = "https://beacondb.net/v1/geolocate";

    # === GRAPHICS & CANVAS ===
    "gfx.canvas.accelerated" = true;
    "gfx.canvas.accelerated.cache-size" = 512; # FastFox
    "gfx.canvas.remote" = false;
    "gfx.wayland.hdr" = true; # Experimental HDR on Wayland (compositor-dependent, may misrender colors)
    "gfx.content.skia-font-cache-size" = 20; # FastFox
    "gfx.vsync.hw-vsync.enabled" = true;

    # === JAVASCRIPT ===
    "javascript.options.baselinejit.threshold" = 50; # FastFox: JIT-compile hot code sooner

    # === IMAGES ===
    "image.avif.enabled" = true;
    "image.jxl.enabled" = true;
    "image.mem.decode_bytes_at_a_time" = 32768; # FastFox

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
    "media.av1.use-dav1d" = false; # Hardware AV1 decode (NVDEC, RTX 3050) via Firefox 153's Vulkan Video path
    "media.eme.enabled" = true;
    "media.ffmpeg.vaapi.enabled" = true; # Enable VAAPI hardware video decoding
    "media.ffmpeg.vaapi-drm-display.enabled" = true; # Enable VAAPI DRM display
    "media.ffvpx.enabled" = true; # Use built-in FFmpeg instead of system
    "media.gpu-process-decoder" = true; # Decode video in the GPU process
    "media.hardwaremediakeys.enabled" = true;
    "media.hardware-video-decoding.enabled" = true; # Enable hardware video decoding
    "media.hardware-video-decoding.force-enabled" = true; # Force hardware video decoding
    "media.hevc.enabled" = true; # Enable HEVC playback
    "media.hls.enabled" = true;
    "media.navigator.mediadatadecoder_vpx_enabled" = true;
    "media.rdd-ffmpeg.enabled" = false; # Disable RDD process for FFmpeg
    "media.rdd-vpx.enabled" = false; # Disable VP8/VP9 in RDD process
    "media.videocontrols.picture-in-picture.video-toggle.enabled" = true;

    # Add these additional media settings for stability
    "media.decoder.doctor.min_crash_count" = 10;
    "media.decoder.doctor.use_crash_guard" = true;
    "media.gmp-manager.updateEnabled" = true;
    "media.gmp.trial-create.enabled" = true;

    # FastFox: media cache tuning
    "media.cache_readahead_limit" = 3600;
    "media.cache_resume_threshold" = 1800;

    # === MOUSE & SCROLLING ===
    # msdPhysics.enabled=false -> spring-physics model is off; weighting model below governs feel
    "general.smoothScroll" = true;
    "general.smoothScroll.currentVelocityWeighting" = 0.15;
    "general.smoothScroll.mouseWheel.durationMinMS" = 80;
    "general.smoothScroll.msdPhysics.enabled" = false;
    "general.smoothScroll.stopDecelerationWeighting" = 0.6;
    "mousewheel.default.delta_multiplier_y" = 300;
    "mousewheel.min_line_scroll_amount" = 10;

    # === NETWORK ===
    "network.trr.mode" = 5; # Disable DNS-over-HTTPS: use system resolver (unbound, split-horizon for Tailscale)
    "network.auth.subresource-http-auth-allow" = 1;
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
    "network.ssl_tokens_cache_capacity" = 10; # Cache 10 SSL session tokens
    "network.buffer.cache.size" = 65535; # 64KB network buffer cache
    "network.buffer.cache.count" = 48; # FastFox
    "network.http.max-connections" = 1800; # FastFox
    "network.http.max-persistent-connections-per-server" = 10; # FastFox
    "network.http.max-urgent-start-excessive-connections-per-host" = 5; # FastFox
    "network.http.request.max-start-delay" = 5; # FastFox

    # === PERMISSIONS ===
    "permissions.default.desktop-notification" = 2;
    "permissions.default.geo" = 2;
    "permissions.manager.defaultsUrl" = "";

    # === PRIVACY & SECURITY ===
    "privacy.antitracking.isolateContentScriptResources" = true; # Isolate extension content-script network access
    "privacy.clearOnShutdown.history" = false;
    "privacy.firstparty.isolate" = false;
    "privacy.globalprivacycontrol.enabled" = true; # GPC: legally-binding "do not sell/share" signal, replaced DNT (removed in FF135)
    "privacy.history.custom" = true;
    "privacy.resistFingerprinting" = false;
    "privacy.trackingprotection.allow_list.baseline.enabled" = true;
    "privacy.trackingprotection.allow_list.convenience.enabled" = true;
    "privacy.trackingprotection.socialtracking.enabled" = true;
    "privacy.userContext.enabled" = true;
    "privacy.userContext.ui.enabled" = true;

    # === SECURITY ===
    "security.OCSP.enabled" = 0;
    "security.pki.crlite_mode" = 2;
    "security.csp.reporting.enabled" = false; # Stop sending CSP-violation reports to report-uri targets
    "security.ssl.treat_unsafe_negotiation_as_broken" = true; # Reject servers with insecure TLS renegotiation
    "security.tls.enable_0rtt_data" = false; # Disable TLS 1.3 0-RTT (replay-attack surface)
    "browser.xul.error_pages.expert_bad_cert" = true; # Show full cert-error detail

    # === SIGN-ON ===
    "signon.formlessCapture.enabled" = true;
    "signon.privateBrowsingCapture.enabled" = true;

    # === SVG ===
    "svg.context-properties.content.enabled" = true;

    # === TELEMETRY ===
    "toolkit.telemetry.archive.enabled" = false;
    "toolkit.telemetry.enabled" = false;
    "toolkit.telemetry.server" = "";
    "toolkit.telemetry.unified" = false;
    "toolkit.telemetry.newProfilePing.enabled" = false;
    "toolkit.telemetry.shutdownPingSender.enabled" = false;
    "toolkit.telemetry.updatePing.enabled" = false;
    "toolkit.telemetry.bhrPing.enabled" = false;
    "toolkit.telemetry.firstShutdownPing.enabled" = false;
    "toolkit.telemetry.coverage.opt-out" = true;
    "toolkit.coverage.opt-out" = true;
    "toolkit.coverage.endpoint.base" = "";

    # === TOOLKIT ===
    "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

    # === WAYLAND SETTINGS ===
    "widget.dmabuf.force-enabled" = false; # Forced dmabuf breaks WebGL/rendering on NVIDIA proprietary driver (Mozilla bug 1634213)
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
  };
}
