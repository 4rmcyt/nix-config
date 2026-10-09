_: {
  programs.firefox.profiles.default.settings = {
    "browser.tabs.groups.smart.enabled" = false;
    "browser.tabs.groups.smart.userEnabled" = false;

    # non-native-titlebar-buttons.enabled=true actually keeps native GTK controls;
    # inTitlebar=0 uses the system titlebar (COSMIC compatibility)
    "browser.tabs.inTitlebar" = 0;
    "widget.gtk.non-native-titlebar-buttons.enabled" = true;
    "widget.gtk.libadwaita-colors.enabled" = false;
    "browser.uidensity" = 1; # 0 = normal, 1 = compact, 2 = touch
    "browser.newtabpage.activity-stream.feeds.topsites" = false;
    "browser.newtabpage.activity-stream.showSponsored" = false;
    "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
    "browser.privatebrowsing.resetPBM.enabled" = true;
    "browser.sessionstore.interval" = 600000;
    "browser.tabs.hoverPreview.enabled" = true;
    "browser.topsites.contile.enabled" = false;

    # msdPhysics.enabled=false: spring-physics model off, weighting settings below govern feel instead
    "general.smoothScroll" = true;
    "general.smoothScroll.currentVelocityWeighting" = 0.15;
    "general.smoothScroll.mouseWheel.durationMinMS" = 80;
    "general.smoothScroll.msdPhysics.enabled" = false;
    "general.smoothScroll.stopDecelerationWeighting" = 0.6;
    "mousewheel.default.delta_multiplier_y" = 300;
    "mousewheel.min_line_scroll_amount" = 10;
  };
}
