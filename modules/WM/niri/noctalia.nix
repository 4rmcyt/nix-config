{pkgs, ...}: let
  # Zed theme template from matugen-themes
  # Pinned to a commit, not refs/heads/main — that branch moved and broke
  # the fixed-output hash once already (upstream edits the file in place).
  zedTemplate = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/InioX/matugen-themes/e4c1d6b7a76e980ffbb93fc57559689cef1f37d6/templates/zed-colors.json";
    sha256 = "0kgwi45qyign1zg8b5jxsavhh3wamshvapvkx9q28xzbi95si142";
  };

  # Materialgram/Telegram theme template (Material You style)
  materialgramTemplate = pkgs.writeText "materialgram.tdesktop-theme" ''
    // Matugen Material You Theme for Materialgram/Telegram
    // Generated colors from wallpaper

    // Window
    windowBg: {{colors.surface.dark.hex}};
    windowFg: {{colors.on_surface.dark.hex}};
    windowBgOver: {{colors.surface_container.dark.hex}};
    windowBgRipple: {{colors.surface_container_high.dark.hex}};
    windowFgOver: {{colors.on_surface.dark.hex}};
    windowSubTextFg: {{colors.on_surface_variant.dark.hex}};
    windowSubTextFgOver: {{colors.on_surface_variant.dark.hex}};
    windowBoldFg: {{colors.on_surface.dark.hex}};
    windowBoldFgOver: {{colors.on_surface.dark.hex}};
    windowBgActive: {{colors.primary.dark.hex}};
    windowFgActive: {{colors.on_primary.dark.hex}};
    windowActiveTextFg: {{colors.primary.dark.hex}};
    windowShadowFg: {{colors.shadow.dark.hex}};
    windowShadowFgFallback: {{colors.shadow.dark.hex}};

    // Shadow
    shadowFg: {{colors.shadow.dark.hex}}18;

    // Slide animation
    slideFadeOutBg: {{colors.surface.dark.hex}};
    slideFadeOutShadowFg: {{colors.shadow.dark.hex}};

    // Image shadow
    imageBg: {{colors.surface_dim.dark.hex}};
    imageBgTransparent: {{colors.surface_dim.dark.hex}};

    // Active button
    activeButtonBg: {{colors.primary.dark.hex}};
    activeButtonBgOver: {{colors.primary_container.dark.hex}};
    activeButtonBgRipple: {{colors.on_primary_container.dark.hex}}33;
    activeButtonFg: {{colors.on_primary.dark.hex}};
    activeButtonFgOver: {{colors.on_primary_container.dark.hex}};
    activeButtonSecondaryFg: {{colors.on_primary.dark.hex}}cc;
    activeButtonSecondaryFgOver: {{colors.on_primary_container.dark.hex}}cc;

    // Light button
    lightButtonBg: {{colors.surface_container.dark.hex}};
    lightButtonBgOver: {{colors.surface_container_high.dark.hex}};
    lightButtonBgRipple: {{colors.surface_container_highest.dark.hex}};
    lightButtonFg: {{colors.primary.dark.hex}};
    lightButtonFgOver: {{colors.primary.dark.hex}};

    // Attention button (destructive actions)
    attentionButtonBg: {{colors.error.dark.hex}};
    attentionButtonBgOver: {{colors.error_container.dark.hex}};
    attentionButtonBgRipple: {{colors.on_error_container.dark.hex}}33;
    attentionButtonFg: {{colors.on_error.dark.hex}};
    attentionButtonFgOver: {{colors.on_error_container.dark.hex}};

    // Outline button
    outlineButtonBg: {{colors.surface.dark.hex}};
    outlineButtonBgOver: {{colors.surface_container_low.dark.hex}};
    outlineButtonOutlineFg: {{colors.primary.dark.hex}};
    outlineButtonBgRipple: {{colors.primary.dark.hex}}22;

    // Menu
    menuBg: {{colors.surface_container.dark.hex}};
    menuBgOver: {{colors.surface_container_high.dark.hex}};
    menuBgRipple: {{colors.surface_container_highest.dark.hex}};
    menuIconFg: {{colors.on_surface_variant.dark.hex}};
    menuIconFgOver: {{colors.on_surface.dark.hex}};
    menuSubmenuArrowFg: {{colors.on_surface_variant.dark.hex}};
    menuFgDisabled: {{colors.on_surface.dark.hex}}66;
    menuSeparatorFg: {{colors.outline_variant.dark.hex}};

    // Scroll bar
    scrollBarBg: {{colors.on_surface_variant.dark.hex}}66;
    scrollBarBgOver: {{colors.on_surface_variant.dark.hex}}99;
    scrollBg: {{colors.surface_container.dark.hex}}66;
    scrollBgOver: {{colors.surface_container.dark.hex}}99;

    // Small close button
    smallCloseIconFg: {{colors.on_surface_variant.dark.hex}};
    smallCloseIconFgOver: {{colors.on_surface.dark.hex}};

    // Radial progress
    radialFg: {{colors.primary.dark.hex}};
    radialBg: {{colors.surface_container.dark.hex}};

    // Placeholder
    placeholderFg: {{colors.on_surface_variant.dark.hex}}99;
    placeholderFgActive: {{colors.on_surface_variant.dark.hex}};

    // Input
    inputBorderFg: {{colors.outline.dark.hex}};

    // Filter checkbox
    filterInputBorderFg: {{colors.primary.dark.hex}};

    // Check/radio
    checkboxFg: {{colors.outline.dark.hex}};

    // Slider
    sliderBgInactive: {{colors.surface_container_highest.dark.hex}};
    sliderBgActive: {{colors.primary.dark.hex}};

    // Tooltip
    tooltipBg: {{colors.inverse_surface.dark.hex}};
    tooltipFg: {{colors.inverse_on_surface.dark.hex}};
    tooltipBorderFg: {{colors.inverse_surface.dark.hex}};

    // Title
    titleShadow: {{colors.shadow.dark.hex}}00;
    titleBg: {{colors.surface.dark.hex}};
    titleBgActive: {{colors.surface.dark.hex}};
    titleButtonBg: {{colors.surface.dark.hex}};
    titleButtonFg: {{colors.on_surface_variant.dark.hex}};
    titleButtonBgOver: {{colors.surface_container.dark.hex}};
    titleButtonFgOver: {{colors.on_surface.dark.hex}};
    titleButtonBgActive: {{colors.surface_container_high.dark.hex}};
    titleButtonFgActive: {{colors.on_surface.dark.hex}};
    titleButtonBgActiveOver: {{colors.surface_container_highest.dark.hex}};
    titleButtonFgActiveOver: {{colors.on_surface.dark.hex}};
    titleButtonCloseBg: {{colors.surface.dark.hex}};
    titleButtonCloseFg: {{colors.on_surface_variant.dark.hex}};
    titleButtonCloseBgOver: {{colors.error_container.dark.hex}};
    titleButtonCloseFgOver: {{colors.on_error_container.dark.hex}};
    titleButtonCloseBgActive: {{colors.error.dark.hex}};
    titleButtonCloseFgActive: {{colors.on_error.dark.hex}};
    titleFg: {{colors.on_surface.dark.hex}};
    titleFgActive: {{colors.on_surface.dark.hex}};

    // Tray icon
    trayCounterBg: {{colors.error.dark.hex}};
    trayCounterBgMute: {{colors.outline.dark.hex}};
    trayCounterFg: {{colors.on_error.dark.hex}};
    trayCounterBgMacInvert: {{colors.on_surface.dark.hex}};
    trayCounterFgMacInvert: {{colors.surface.dark.hex}};

    // Layers
    layerBg: {{colors.scrim.dark.hex}}99;

    // Cancel icon
    cancelIconFg: {{colors.on_surface_variant.dark.hex}};
    cancelIconFgOver: {{colors.on_surface.dark.hex}};

    // Box
    boxBg: {{colors.surface_container.dark.hex}};
    boxTextFg: {{colors.on_surface.dark.hex}};
    boxTextFgGood: {{colors.tertiary.dark.hex}};
    boxTextFgError: {{colors.error.dark.hex}};
    boxTitleFg: {{colors.on_surface.dark.hex}};
    boxSearchBg: {{colors.surface_container_low.dark.hex}};
    boxTitleAdditionalFg: {{colors.on_surface_variant.dark.hex}};
    boxTitleCloseFg: {{colors.on_surface_variant.dark.hex}};
    boxTitleCloseFgOver: {{colors.on_surface.dark.hex}};

    // Members
    membersAboutLimitFg: {{colors.on_surface_variant.dark.hex}};

    // Contacts
    contactsBg: {{colors.surface.dark.hex}};
    contactsBgOver: {{colors.surface_container.dark.hex}};
    contactsNameFg: {{colors.on_surface.dark.hex}};
    contactsStatusFg: {{colors.on_surface_variant.dark.hex}};
    contactsStatusFgOver: {{colors.on_surface_variant.dark.hex}};
    contactsStatusFgOnline: {{colors.primary.dark.hex}};

    // Photos
    photoCropFadeBg: {{colors.scrim.dark.hex}}cc;
    photoCropPointFg: {{colors.primary.dark.hex}};

    // Intro
    introBg: {{colors.surface.dark.hex}};
    introTitleFg: {{colors.on_surface.dark.hex}};
    introDescriptionFg: {{colors.on_surface_variant.dark.hex}};
    introErrorFg: {{colors.error.dark.hex}};
    introCoverTopBg: {{colors.primary.dark.hex}};
    introCoverBottomBg: {{colors.primary_container.dark.hex}};
    introCoverIconsFg: {{colors.on_primary.dark.hex}};
    introCoverPlaneTrace: {{colors.on_primary.dark.hex}}66;
    introCoverPlaneInner: {{colors.on_primary_container.dark.hex}};
    introCoverPlaneOuter: {{colors.primary.dark.hex}};
    introCoverPlaneTop: {{colors.on_primary.dark.hex}};

    // Dialogs
    dialogsMenuIconFg: {{colors.on_surface_variant.dark.hex}};
    dialogsMenuIconFgOver: {{colors.on_surface.dark.hex}};
    dialogsBg: {{colors.surface.dark.hex}};
    dialogsNameFg: {{colors.on_surface.dark.hex}};
    dialogsChatIconFg: {{colors.primary.dark.hex}};
    dialogsDateFg: {{colors.on_surface_variant.dark.hex}};
    dialogsTextFg: {{colors.on_surface_variant.dark.hex}};
    dialogsTextFgService: {{colors.primary.dark.hex}};
    dialogsDraftFg: {{colors.error.dark.hex}};
    dialogsVerifiedIconBg: {{colors.primary.dark.hex}};
    dialogsVerifiedIconFg: {{colors.on_primary.dark.hex}};
    dialogsSendingIconFg: {{colors.primary.dark.hex}};
    dialogsSentIconFg: {{colors.primary.dark.hex}};
    dialogsUnreadBg: {{colors.primary.dark.hex}};
    dialogsUnreadBgMuted: {{colors.outline.dark.hex}};
    dialogsUnreadFg: {{colors.on_primary.dark.hex}};
    dialogsBgOver: {{colors.surface_container.dark.hex}};
    dialogsBgActive: {{colors.primary_container.dark.hex}};
    dialogsNameFgOver: {{colors.on_surface.dark.hex}};
    dialogsChatIconFgOver: {{colors.primary.dark.hex}};
    dialogsDateFgOver: {{colors.on_surface_variant.dark.hex}};
    dialogsTextFgOver: {{colors.on_surface_variant.dark.hex}};
    dialogsTextFgServiceOver: {{colors.primary.dark.hex}};
    dialogsDraftFgOver: {{colors.error.dark.hex}};
    dialogsVerifiedIconBgOver: {{colors.primary.dark.hex}};
    dialogsVerifiedIconFgOver: {{colors.on_primary.dark.hex}};
    dialogsSendingIconFgOver: {{colors.primary.dark.hex}};
    dialogsSentIconFgOver: {{colors.primary.dark.hex}};
    dialogsUnreadBgOver: {{colors.primary.dark.hex}};
    dialogsUnreadBgMutedOver: {{colors.outline.dark.hex}};
    dialogsUnreadFgOver: {{colors.on_primary.dark.hex}};
    dialogsNameFgActive: {{colors.on_primary_container.dark.hex}};
    dialogsChatIconFgActive: {{colors.on_primary_container.dark.hex}};
    dialogsDateFgActive: {{colors.on_primary_container.dark.hex}}cc;
    dialogsTextFgActive: {{colors.on_primary_container.dark.hex}}cc;
    dialogsTextFgServiceActive: {{colors.on_primary_container.dark.hex}};
    dialogsDraftFgActive: {{colors.error.dark.hex}};
    dialogsVerifiedIconBgActive: {{colors.on_primary_container.dark.hex}};
    dialogsVerifiedIconFgActive: {{colors.primary_container.dark.hex}};
    dialogsSendingIconFgActive: {{colors.on_primary_container.dark.hex}};
    dialogsSentIconFgActive: {{colors.on_primary_container.dark.hex}};
    dialogsUnreadBgActive: {{colors.on_primary_container.dark.hex}};
    dialogsUnreadBgMutedActive: {{colors.on_primary_container.dark.hex}}99;
    dialogsUnreadFgActive: {{colors.primary_container.dark.hex}};
    dialogsForwardBg: {{colors.primary.dark.hex}};
    dialogsForwardFg: {{colors.on_primary.dark.hex}};

    // Search
    searchedBarBg: {{colors.surface_container.dark.hex}};
    searchedBarFg: {{colors.on_surface_variant.dark.hex}};

    // History
    topBarBg: {{colors.surface.dark.hex}};

    // Emoji panel
    emojiPanBg: {{colors.surface_container.dark.hex}};
    emojiPanCategories: {{colors.surface_container_low.dark.hex}};
    emojiPanHeaderFg: {{colors.on_surface_variant.dark.hex}};
    emojiPanHeaderBg: {{colors.surface_container.dark.hex}};
    emojiIconFg: {{colors.on_surface_variant.dark.hex}};
    emojiIconFgActive: {{colors.primary.dark.hex}};

    // Sticker panel
    stickerPanHeaderFg: {{colors.on_surface_variant.dark.hex}};
    stickerPanHeaderBg: {{colors.surface_container.dark.hex}};
    stickerPreviewBg: {{colors.surface_container.dark.hex}};

    // History
    historyTextInFg: {{colors.on_surface.dark.hex}};
    historyTextInFgSelected: {{colors.on_surface.dark.hex}};
    historyTextOutFg: {{colors.on_primary_container.dark.hex}};
    historyTextOutFgSelected: {{colors.on_primary_container.dark.hex}};
    historyLinkInFg: {{colors.primary.dark.hex}};
    historyLinkInFgSelected: {{colors.primary.dark.hex}};
    historyLinkOutFg: {{colors.on_primary_container.dark.hex}};
    historyLinkOutFgSelected: {{colors.on_primary_container.dark.hex}};
    historyFileNameInFg: {{colors.on_surface.dark.hex}};
    historyFileNameInFgSelected: {{colors.on_surface.dark.hex}};
    historyFileNameOutFg: {{colors.on_primary_container.dark.hex}};
    historyFileNameOutFgSelected: {{colors.on_primary_container.dark.hex}};
    historyOutIconFg: {{colors.primary.dark.hex}};
    historyOutIconFgSelected: {{colors.primary.dark.hex}};
    historyIconFgInverted: {{colors.on_primary.dark.hex}};
    historySendingOutIconFg: {{colors.primary.dark.hex}};
    historySendingInIconFg: {{colors.primary.dark.hex}};
    historySendingInvertedIconFg: {{colors.on_primary.dark.hex}};
    historyUnreadBarBg: {{colors.surface_container_high.dark.hex}};
    historyUnreadBarBorder: {{colors.surface_container_high.dark.hex}};
    historyUnreadBarFg: {{colors.on_surface_variant.dark.hex}};
    historyForwardChooseBg: {{colors.scrim.dark.hex}}99;
    historyForwardChooseFg: {{colors.inverse_on_surface.dark.hex}};
    historyPeer1NameFg: {{colors.error.dark.hex}};
    historyPeer1NameFgSelected: {{colors.error.dark.hex}};
    historyPeer1UserpicBg: {{colors.error_container.dark.hex}};
    historyPeer2NameFg: {{colors.tertiary.dark.hex}};
    historyPeer2NameFgSelected: {{colors.tertiary.dark.hex}};
    historyPeer2UserpicBg: {{colors.tertiary_container.dark.hex}};
    historyPeer3NameFg: {{colors.secondary.dark.hex}};
    historyPeer3NameFgSelected: {{colors.secondary.dark.hex}};
    historyPeer3UserpicBg: {{colors.secondary_container.dark.hex}};
    historyPeer4NameFg: {{colors.primary.dark.hex}};
    historyPeer4NameFgSelected: {{colors.primary.dark.hex}};
    historyPeer4UserpicBg: {{colors.primary_container.dark.hex}};
    historyPeer5NameFg: {{colors.tertiary.dark.hex}};
    historyPeer5NameFgSelected: {{colors.tertiary.dark.hex}};
    historyPeer5UserpicBg: {{colors.tertiary_container.dark.hex}};
    historyPeer6NameFg: {{colors.error.dark.hex}};
    historyPeer6NameFgSelected: {{colors.error.dark.hex}};
    historyPeer6UserpicBg: {{colors.error_container.dark.hex}};
    historyPeer7NameFg: {{colors.secondary.dark.hex}};
    historyPeer7NameFgSelected: {{colors.secondary.dark.hex}};
    historyPeer7UserpicBg: {{colors.secondary_container.dark.hex}};
    historyPeer8NameFg: {{colors.primary.dark.hex}};
    historyPeer8NameFgSelected: {{colors.primary.dark.hex}};
    historyPeer8UserpicBg: {{colors.primary_container.dark.hex}};
    historyPeerUserpicFg: {{colors.on_primary_container.dark.hex}};
    historyScrollBarBg: {{colors.on_surface_variant.dark.hex}}66;
    historyScrollBarBgOver: {{colors.on_surface_variant.dark.hex}}99;
    historyScrollBg: {{colors.surface_container.dark.hex}}66;
    historyScrollBgOver: {{colors.surface_container.dark.hex}}99;

    // Message bubble
    msgInBg: {{colors.surface_container.dark.hex}};
    msgInBgSelected: {{colors.surface_container_highest.dark.hex}};
    msgOutBg: {{colors.primary_container.dark.hex}};
    msgOutBgSelected: {{colors.primary.dark.hex}}44;
    msgSelectOverlay: {{colors.primary.dark.hex}}33;
    msgStickerOverlay: {{colors.primary.dark.hex}}33;
    msgInServiceFg: {{colors.primary.dark.hex}};
    msgInServiceFgSelected: {{colors.primary.dark.hex}};
    msgOutServiceFg: {{colors.on_primary_container.dark.hex}};
    msgOutServiceFgSelected: {{colors.on_primary_container.dark.hex}};
    msgInShadow: {{colors.shadow.dark.hex}}18;
    msgInShadowSelected: {{colors.shadow.dark.hex}}22;
    msgOutShadow: {{colors.shadow.dark.hex}}18;
    msgOutShadowSelected: {{colors.shadow.dark.hex}}22;
    msgInDateFg: {{colors.on_surface_variant.dark.hex}};
    msgInDateFgSelected: {{colors.on_surface_variant.dark.hex}};
    msgOutDateFg: {{colors.on_primary_container.dark.hex}}cc;
    msgOutDateFgSelected: {{colors.on_primary_container.dark.hex}}cc;
    msgServiceFg: {{colors.inverse_on_surface.dark.hex}};
    msgServiceBg: {{colors.inverse_surface.dark.hex}}cc;
    msgServiceBgSelected: {{colors.inverse_surface.dark.hex}};
    msgInReplyBarColor: {{colors.primary.dark.hex}};
    msgInReplyBarSelColor: {{colors.primary.dark.hex}};
    msgOutReplyBarColor: {{colors.on_primary_container.dark.hex}};
    msgOutReplyBarSelColor: {{colors.on_primary_container.dark.hex}};
    msgImgReplyBarColor: {{colors.on_primary.dark.hex}};
    msgInMonoFg: {{colors.tertiary.dark.hex}};
    msgInMonoFgSelected: {{colors.tertiary.dark.hex}};
    msgOutMonoFg: {{colors.on_tertiary_container.dark.hex}};
    msgOutMonoFgSelected: {{colors.on_tertiary_container.dark.hex}};
    msgDateImgFg: {{colors.on_surface.dark.hex}};
    msgDateImgBg: {{colors.scrim.dark.hex}}99;
    msgDateImgBgOver: {{colors.scrim.dark.hex}}cc;
    msgDateImgBgSelected: {{colors.primary.dark.hex}}cc;
    msgFileThumbLinkInFg: {{colors.primary.dark.hex}};
    msgFileThumbLinkInFgSelected: {{colors.primary.dark.hex}};
    msgFileThumbLinkOutFg: {{colors.on_primary_container.dark.hex}};
    msgFileThumbLinkOutFgSelected: {{colors.on_primary_container.dark.hex}};
    msgFileInBg: {{colors.primary.dark.hex}};
    msgFileInBgOver: {{colors.primary_container.dark.hex}};
    msgFileInBgSelected: {{colors.primary.dark.hex}};
    msgFileOutBg: {{colors.on_primary_container.dark.hex}};
    msgFileOutBgOver: {{colors.on_primary_container.dark.hex}}cc;
    msgFileOutBgSelected: {{colors.on_primary_container.dark.hex}};

    // Sent message checks
    msgFile1Bg: {{colors.primary.dark.hex}};
    msgFile1BgDark: {{colors.primary.dark.hex}};
    msgFile1BgOver: {{colors.primary_container.dark.hex}};
    msgFile1BgSelected: {{colors.primary.dark.hex}};
    msgFile2Bg: {{colors.tertiary.dark.hex}};
    msgFile2BgDark: {{colors.tertiary.dark.hex}};
    msgFile2BgOver: {{colors.tertiary_container.dark.hex}};
    msgFile2BgSelected: {{colors.tertiary.dark.hex}};
    msgFile3Bg: {{colors.error.dark.hex}};
    msgFile3BgDark: {{colors.error.dark.hex}};
    msgFile3BgOver: {{colors.error_container.dark.hex}};
    msgFile3BgSelected: {{colors.error.dark.hex}};
    msgFile4Bg: {{colors.secondary.dark.hex}};
    msgFile4BgDark: {{colors.secondary.dark.hex}};
    msgFile4BgOver: {{colors.secondary_container.dark.hex}};
    msgFile4BgSelected: {{colors.secondary.dark.hex}};

    // Compose
    historyComposeAreaBg: {{colors.surface.dark.hex}};
    historyComposeAreaFg: {{colors.on_surface.dark.hex}};
    historyComposeAreaFgService: {{colors.primary.dark.hex}};
    historyComposeIconFg: {{colors.on_surface_variant.dark.hex}};
    historyComposeIconFgOver: {{colors.on_surface.dark.hex}};
    historySendIconFg: {{colors.primary.dark.hex}};
    historySendIconFgOver: {{colors.primary_container.dark.hex}};
    historyPinnedBg: {{colors.surface_container.dark.hex}};
    historyReplyBg: {{colors.surface_container.dark.hex}};
    historyReplyIconFg: {{colors.primary.dark.hex}};
    historyReplyCancelFg: {{colors.on_surface_variant.dark.hex}};
    historyReplyCancelFgOver: {{colors.on_surface.dark.hex}};

    // History message actions
    historyToDownBg: {{colors.surface_container.dark.hex}};
    historyToDownBgOver: {{colors.surface_container_high.dark.hex}};
    historyToDownBgRipple: {{colors.surface_container_highest.dark.hex}};
    historyToDownFg: {{colors.on_surface_variant.dark.hex}};
    historyToDownFgOver: {{colors.on_surface.dark.hex}};
    historyToDownShadow: {{colors.shadow.dark.hex}}66;

    // Overview
    overviewCheckBg: {{colors.primary.dark.hex}}cc;
    overviewCheckBgActive: {{colors.primary.dark.hex}};
    overviewCheckBgHover: {{colors.primary_container.dark.hex}};
    overviewCheckFg: {{colors.on_primary.dark.hex}};
    overviewCheckFgActive: {{colors.on_primary.dark.hex}};
    overviewPhotoSelectOverlay: {{colors.scrim.dark.hex}}66;

    // Profile
    profileStatusFgOver: {{colors.on_surface_variant.dark.hex}};
    profileVerifiedCheckBg: {{colors.primary.dark.hex}};
    profileVerifiedCheckFg: {{colors.on_primary.dark.hex}};
    profileAdminStartFg: {{colors.secondary.dark.hex}};
    profileAdminStarFgOver: {{colors.secondary.dark.hex}};
    profileOtherAdminStarFg: {{colors.outline.dark.hex}};
    profileOtherAdminStarFgOver: {{colors.outline.dark.hex}};

    // Notifications
    notificationsBoxMonitorFg: {{colors.on_surface.dark.hex}};
    notificationsBoxScreenBg: {{colors.surface_container_low.dark.hex}};
    notificationSampleUserpicFg: {{colors.primary.dark.hex}};
    notificationSampleCloseFg: {{colors.on_surface_variant.dark.hex}};
    notificationSampleTextFg: {{colors.on_surface_variant.dark.hex}};
    notificationSampleNameFg: {{colors.on_surface.dark.hex}};

    // Changelog
    changelogCloseFg: {{colors.on_surface_variant.dark.hex}};
    changelogCloseFgOver: {{colors.on_surface.dark.hex}};

    // Main menu
    mainMenuBg: {{colors.surface.dark.hex}};
    mainMenuCoverBg: {{colors.primary_container.dark.hex}};
    mainMenuCoverFg: {{colors.on_primary_container.dark.hex}};
    mainMenuCloudFg: {{colors.primary.dark.hex}};
    mainMenuCloudBg: {{colors.surface_container.dark.hex}};

    // Media
    mediaInFg: {{colors.on_surface_variant.dark.hex}};
    mediaInFgSelected: {{colors.on_surface_variant.dark.hex}};
    mediaOutFg: {{colors.on_primary_container.dark.hex}}cc;
    mediaOutFgSelected: {{colors.on_primary_container.dark.hex}}cc;

    // Media player
    mediaPlayerBg: {{colors.surface.dark.hex}};
    mediaPlayerActiveFg: {{colors.primary.dark.hex}};
    mediaPlayerInactiveFg: {{colors.outline.dark.hex}};
    mediaPlayerDisabledFg: {{colors.outline_variant.dark.hex}};

    // Media view
    mediaviewFileBg: {{colors.surface_container.dark.hex}};
    mediaviewFileNameFg: {{colors.on_surface.dark.hex}};
    mediaviewFileSizeFg: {{colors.on_surface_variant.dark.hex}};
    mediaviewFileRedCornerFg: {{colors.error.dark.hex}};
    mediaviewFileYellowCornerFg: {{colors.secondary.dark.hex}};
    mediaviewFileGreenCornerFg: {{colors.tertiary.dark.hex}};
    mediaviewFileBlueCornerFg: {{colors.primary.dark.hex}};
    mediaviewFileExtFg: {{colors.on_primary.dark.hex}};
    mediaviewMenuBg: {{colors.surface_container.dark.hex}};
    mediaviewMenuBgOver: {{colors.surface_container_high.dark.hex}};
    mediaviewMenuFg: {{colors.on_surface.dark.hex}};
    mediaviewBg: {{colors.scrim.dark.hex}}ee;
    mediaviewVideoBg: {{colors.surface_dim.dark.hex}};
    mediaviewControlBg: {{colors.surface_container.dark.hex}}cc;
    mediaviewControlFg: {{colors.on_surface.dark.hex}};
    mediaviewCaptionBg: {{colors.surface_container.dark.hex}}cc;
    mediaviewCaptionFg: {{colors.on_surface.dark.hex}};
    mediaviewTextLinkFg: {{colors.primary.dark.hex}};
    mediaviewSaveMsgBg: {{colors.inverse_surface.dark.hex}};
    mediaviewSaveMsgFg: {{colors.inverse_on_surface.dark.hex}};
    mediaviewPlaybackActive: {{colors.primary.dark.hex}};
    mediaviewPlaybackInactive: {{colors.outline.dark.hex}};
    mediaviewPlaybackActiveOver: {{colors.primary_container.dark.hex}};
    mediaviewPlaybackInactiveOver: {{colors.outline_variant.dark.hex}};
    mediaviewPlaybackProgressFg: {{colors.on_surface.dark.hex}};
    mediaviewPlaybackIconFg: {{colors.on_surface.dark.hex}};
    mediaviewPlaybackIconFgOver: {{colors.primary.dark.hex}};
    mediaviewTransparentBg: {{colors.surface_dim.dark.hex}};
    mediaviewTransparentFg: {{colors.outline.dark.hex}};

    // Calls
    callBg: {{colors.surface.dark.hex}};
    callNameFg: {{colors.on_surface.dark.hex}};
    callFingerprintBg: {{colors.surface_container.dark.hex}};
    callStatusFg: {{colors.on_surface_variant.dark.hex}};
    callIconFg: {{colors.primary.dark.hex}};
    callAnswerBg: {{colors.tertiary.dark.hex}};
    callAnswerRipple: {{colors.tertiary_container.dark.hex}};
    callAnswerBgOuter: {{colors.tertiary.dark.hex}}44;
    callHangupBg: {{colors.error.dark.hex}};
    callHangupRipple: {{colors.error_container.dark.hex}};
    callCancelBg: {{colors.surface_container.dark.hex}};
    callCancelFg: {{colors.on_surface.dark.hex}};
    callCancelRipple: {{colors.surface_container_high.dark.hex}};
    callMuteRipple: {{colors.surface_container_highest.dark.hex}};

    // Import
    importOptionBg: {{colors.surface_container.dark.hex}};
    importOptionBgHover: {{colors.surface_container_high.dark.hex}};
    importOptionTitle: {{colors.on_surface.dark.hex}};
    importOptionInfo: {{colors.on_surface_variant.dark.hex}};
  '';
in {
  # Template source files, rendered by noctalia's TemplateEngine into the
  # paths below. See https://docs.noctalia.dev/noctalia/theming/app-theming/#user-templates
  xdg.configFile = {
    "noctalia/templates/zed-colors.json".source = zedTemplate;
    "noctalia/templates/materialgram.tdesktop-theme".source = materialgramTemplate;
  };

  programs.noctalia = {
    enable = true;
    # spawn-at-startup configured in startup.nix; systemd service not used

    settings = {
      theme.templates.user = {
        zed-dark = {
          input_path = "$XDG_CONFIG_HOME/noctalia/templates/zed-colors.json";
          output_path = "$XDG_CONFIG_HOME/zed/themes/matugen.json";
        };
        materialgram = {
          input_path = "$XDG_CONFIG_HOME/noctalia/templates/materialgram.tdesktop-theme";
          output_path = "$HOME/.local/share/TelegramDesktop/tdata/matugen.tdesktop-theme";
        };
      };
    };
  };

  # playerctl for media key bindings
  home.packages = [pkgs.playerctl];
}
