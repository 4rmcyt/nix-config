_: {
  programs.firefox.profiles.default.settings = {
    "accessibility.typeaheadfind.enablesound" = false;
    "general.autoScroll" = true;

    "app.normandy.enabled" = false;
    "app.normandy.api_url" = "";
    "app.shield.optoutstudies.enabled" = false;

    "breakpad.reportURL" = "";

    "browser.ml.enable" = false;
    "browser.ml.chat.enabled" = false;
    "browser.ml.chat.sidebar" = false;
    "browser.ml.chat.menu" = false;
    "browser.ml.chat.page" = false;
    "browser.ml.linkPreview.enabled" = false;
    "browser.ml.pageAssist.enabled" = false;
    "browser.ml.smartAssist.enabled" = false;
    "extensions.ml.enabled" = false;
    "browser.tabs.groups.smart.enabled" = false;
    "browser.tabs.groups.smart.userEnabled" = false;
    "pdfjs.enableAltTextModelDownload" = false;
    "pdfjs.enableGuessAltText" = false;
    "pdfjs.enableScripting" = false;
    "browser.ai.control.default" = "blocked"; # unified AI kill switch, FF152+

    "apz.overscroll.enabled" = true;

    # non-native-titlebar-buttons.enabled=true actually keeps native GTK controls;
    # inTitlebar=0 uses the system titlebar (COSMIC compatibility)
    "browser.tabs.inTitlebar" = 0;
    "widget.gtk.non-native-titlebar-buttons.enabled" = true;
    "layout.css.devPixelsPerPx" = "2.0";
    "widget.gtk.libadwaita-colors.enabled" = false;
    "browser.aboutConfig.showWarning" = false;
    "browser.aboutwelcome.enabled" = false;
    "browser.discovery.enabled" = false;
    "browser.preferences.moreFromMozilla" = false;
    "browser.uidensity" = 1; # 0 = normal, 1 = compact, 2 = touch
    "content.notify.interval" = 100000;
    "browser.cache.disk.enable" = false;
    "browser.cache.memory.enable" = true;
    "browser.cache.frecency_half_life_hours" = 18;
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
    "browser.sessionstore.interval" = 600000;
    "browser.sessionhistory.max_entries" = 5;
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

    "datareporting.healthreport.uploadEnabled" = false;
    "datareporting.policy.dataSubmissionEnabled" = false;
    "datareporting.usage.uploadEnabled" = false;

    "devtools.chrome.enabled" = true;

    "dom.battery.enabled" = false;
    "dom.ipc.processPriorityManager.backgroundUsesEcoQoS" = true;
    "dom.private-attribution.submission.enabled" = false;
    "dom.webgpu.enabled" = true;

    "editor.truncate_user_pastes" = false;

    "extensions.abuseReport.enabled" = false;
    "extensions.autoDisableScopes" = 0;
    "extensions.formautofill.creditCards.enabled" = true;
    "extensions.getAddons.cache.enabled" = false;
    "extensions.update.enabled" = true;
    "extensions.webcompat-reporter.enabled" = false;
    "extensions.webextensions.ExtensionStorageIDB.enabled" = false;

    "geo.provider.network.url" = "https://beacondb.net/v1/geolocate";

    "gfx.canvas.accelerated" = true;
    "gfx.canvas.accelerated.cache-size" = 512;
    "gfx.canvas.remote" = false;
    "gfx.wayland.hdr" = true; # experimental; compositor-dependent, may misrender colors
    "gfx.content.skia-font-cache-size" = 20;
    "gfx.vsync.hw-vsync.enabled" = true;

    "javascript.options.baselinejit.threshold" = 50;

    "image.avif.enabled" = true;
    "image.jxl.enabled" = true;
    "image.mem.decode_bytes_at_a_time" = 32768;

    "identity.fxaccounts.commands.enabled" = true;
    "identity.fxaccounts.enabled" = true;
    "identity.fxaccounts.pairing.enabled" = true;
    "identity.fxaccounts.toolbar.enabled" = true;

    "intl.accept_languages" = "en-US,en";

    "layers.acceleration.disabled" = false;
    "layers.gpu-process.enabled" = true;
    "layers.mlgpu.enabled" = true;
    "layers.omtp.enabled" = false;

    "media.av1.enabled" = true;
    # AV1 sw decode: NVIDIA hw decode needs Turing/RTX-20-series+; not a Wayland limitation —
    # real fix was MOZ_DISABLE_RDD_SANDBOX=1 (modules/WM/mango/nvidia.nix)
    "media.av1.use-dav1d" = true;
    "media.eme.enabled" = true;
    "media.ffmpeg.vaapi.enabled" = true;
    "media.ffmpeg.vaapi-drm-display.enabled" = true;
    "media.ffvpx.enabled" = true;
    "media.gpu-process-decoder" = true;
    "media.hardwaremediakeys.enabled" = true;
    "media.hardware-video-decoding.enabled" = true;
    # If about:support still shows NVIDIA blocklisted after rebuild, try true —
    # real cause was missing MOZ_DISABLE_RDD_SANDBOX=1 (modules/WM/mango/nvidia.nix)
    "media.hardware-video-decoding.force-enabled" = false;
    "media.hevc.enabled" = true;
    "media.hls.enabled" = true;
    "media.navigator.mediadatadecoder_vpx_enabled" = true;
    "media.rdd-ffmpeg.enabled" = true;
    "media.rdd-vpx.enabled" = true;
    "media.videocontrols.picture-in-picture.video-toggle.enabled" = true;

    "media.decoder.doctor.min_crash_count" = 10;
    "media.decoder.doctor.use_crash_guard" = true;
    "media.gmp-manager.updateEnabled" = true;
    "media.gmp.trial-create.enabled" = true;

    "media.cache_readahead_limit" = 3600;
    "media.cache_resume_threshold" = 1800;

    # msdPhysics.enabled=false: spring-physics model off, weighting settings below govern feel instead
    "general.smoothScroll" = true;
    "general.smoothScroll.currentVelocityWeighting" = 0.15;
    "general.smoothScroll.mouseWheel.durationMinMS" = 80;
    "general.smoothScroll.msdPhysics.enabled" = false;
    "general.smoothScroll.stopDecelerationWeighting" = 0.6;
    "mousewheel.default.delta_multiplier_y" = 300;
    "mousewheel.min_line_scroll_amount" = 10;

    "network.trr.mode" = 5; # use system resolver (unbound, split-horizon for Tailscale)
    "network.auth.subresource-http-auth-allow" = 1;
    "network.http.http3.enabled" = true;
    "network.http.referer.XOriginTrimmingPolicy" = 2;
    "network.prefetch-next" = false;
    "network.dnsCacheExpiration" = 3600;
    "network.dnsCacheExpirationGracePeriod" = 240;
    "network.predictor.enable-hover-on-ssl" = true;
    "network.predictor.enable-prefetch" = true;
    "network.predictor.preconnect-min-confidence" = 20;
    "network.predictor.prefetch-force-valid-for" = 3600;
    "network.predictor.prefetch-min-confidence" = 30;
    "network.predictor.prefetch-rolling-load-count" = 120;
    "network.predictor.preresolve-min-confidence" = 10;
    "network.ssl_tokens_cache_capacity" = 10;
    "network.buffer.cache.size" = 65535;
    "network.buffer.cache.count" = 48;
    "network.http.max-connections" = 1800;
    "network.http.max-persistent-connections-per-server" = 10;
    "network.http.max-urgent-start-excessive-connections-per-host" = 5;
    "network.http.request.max-start-delay" = 5;

    "permissions.default.desktop-notification" = 2;
    "permissions.default.geo" = 2;
    "permissions.manager.defaultsUrl" = "";

    "privacy.antitracking.isolateContentScriptResources" = true;
    "privacy.clearOnShutdown.history" = false;
    "privacy.firstparty.isolate" = false;
    "privacy.globalprivacycontrol.enabled" = true; # GPC replaced DNT (removed in FF135)
    "privacy.history.custom" = true;
    "privacy.resistFingerprinting" = false;
    "privacy.trackingprotection.allow_list.baseline.enabled" = true;
    "privacy.trackingprotection.allow_list.convenience.enabled" = true;
    "privacy.trackingprotection.socialtracking.enabled" = true;
    "privacy.userContext.enabled" = true;
    "privacy.userContext.ui.enabled" = true;

    "security.OCSP.enabled" = 0;
    "security.pki.crlite_mode" = 2;
    "security.csp.reporting.enabled" = false;
    "security.ssl.treat_unsafe_negotiation_as_broken" = true;
    "security.tls.enable_0rtt_data" = false; # avoids TLS 1.3 0-RTT replay-attack surface
    "browser.xul.error_pages.expert_bad_cert" = true;

    "signon.formlessCapture.enabled" = true;
    "signon.privateBrowsingCapture.enabled" = true;

    "svg.context-properties.content.enabled" = true;

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

    "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

    "widget.dmabuf.force-enabled" = false; # forced dmabuf breaks WebGL on NVIDIA proprietary driver (Mozilla bug 1634213)
    "widget.gtk.wayland.force-enabled" = true;
    "widget.gtk.wayland.fractional-scaling.enabled" = true;
    "widget.use-xdg-desktop-portal.file-picker" = 1;
    "widget.use-xdg-desktop-portal.location" = 1;
    "widget.use-xdg-desktop-portal.mime-handler" = 1;
    "widget.use-xdg-desktop-portal.open-uri" = 1;
    "widget.use-xdg-desktop-portal.settings" = 1;

    "webgl.disabled" = false;
    "webgl.msaa-force" = false;
  };
}
