{
  lib,
  pkgs,
  ...
}: let
  # Zed theme template from matugen-themes
  zedTemplate = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/InioX/matugen-themes/refs/heads/main/templates/zed-colors.json";
    sha256 = "154zpd7f4q3gf5jm6650bghbgyinz85vc8snn73127r2i6w672x8";
  };

  # Materialgram/Telegram theme template (Material You style)
  materialgramTemplate = pkgs.writeText "materialgram.tdesktop-theme" ''
    // Matugen Material You Theme for Materialgram/Telegram
    // Generated colors from wallpaper

    // Window
    windowBg: {{colors.surface.default.hex}};
    windowFg: {{colors.on_surface.default.hex}};
    windowBgOver: {{colors.surface_container.default.hex}};
    windowBgRipple: {{colors.surface_container_high.default.hex}};
    windowFgOver: {{colors.on_surface.default.hex}};
    windowSubTextFg: {{colors.on_surface_variant.default.hex}};
    windowSubTextFgOver: {{colors.on_surface_variant.default.hex}};
    windowBoldFg: {{colors.on_surface.default.hex}};
    windowBoldFgOver: {{colors.on_surface.default.hex}};
    windowBgActive: {{colors.primary.default.hex}};
    windowFgActive: {{colors.on_primary.default.hex}};
    windowActiveTextFg: {{colors.primary.default.hex}};
    windowShadowFg: {{colors.shadow.default.hex}};
    windowShadowFgFallback: {{colors.shadow.default.hex}};

    // Shadow
    shadowFg: {{colors.shadow.default.hex}}18;

    // Slide animation
    slideFadeOutBg: {{colors.surface.default.hex}};
    slideFadeOutShadowFg: {{colors.shadow.default.hex}};

    // Image shadow
    imageBg: {{colors.surface_dim.default.hex}};
    imageBgTransparent: {{colors.surface_dim.default.hex}};

    // Active button
    activeButtonBg: {{colors.primary.default.hex}};
    activeButtonBgOver: {{colors.primary_container.default.hex}};
    activeButtonBgRipple: {{colors.on_primary_container.default.hex}}33;
    activeButtonFg: {{colors.on_primary.default.hex}};
    activeButtonFgOver: {{colors.on_primary_container.default.hex}};
    activeButtonSecondaryFg: {{colors.on_primary.default.hex}}cc;
    activeButtonSecondaryFgOver: {{colors.on_primary_container.default.hex}}cc;

    // Light button
    lightButtonBg: {{colors.surface_container.default.hex}};
    lightButtonBgOver: {{colors.surface_container_high.default.hex}};
    lightButtonBgRipple: {{colors.surface_container_highest.default.hex}};
    lightButtonFg: {{colors.primary.default.hex}};
    lightButtonFgOver: {{colors.primary.default.hex}};

    // Attention button (destructive actions)
    attentionButtonBg: {{colors.error.default.hex}};
    attentionButtonBgOver: {{colors.error_container.default.hex}};
    attentionButtonBgRipple: {{colors.on_error_container.default.hex}}33;
    attentionButtonFg: {{colors.on_error.default.hex}};
    attentionButtonFgOver: {{colors.on_error_container.default.hex}};

    // Outline button
    outlineButtonBg: {{colors.surface.default.hex}};
    outlineButtonBgOver: {{colors.surface_container_low.default.hex}};
    outlineButtonOutlineFg: {{colors.primary.default.hex}};
    outlineButtonBgRipple: {{colors.primary.default.hex}}22;

    // Menu
    menuBg: {{colors.surface_container.default.hex}};
    menuBgOver: {{colors.surface_container_high.default.hex}};
    menuBgRipple: {{colors.surface_container_highest.default.hex}};
    menuIconFg: {{colors.on_surface_variant.default.hex}};
    menuIconFgOver: {{colors.on_surface.default.hex}};
    menuSubmenuArrowFg: {{colors.on_surface_variant.default.hex}};
    menuFgDisabled: {{colors.on_surface.default.hex}}66;
    menuSeparatorFg: {{colors.outline_variant.default.hex}};

    // Scroll bar
    scrollBarBg: {{colors.on_surface_variant.default.hex}}66;
    scrollBarBgOver: {{colors.on_surface_variant.default.hex}}99;
    scrollBg: {{colors.surface_container.default.hex}}66;
    scrollBgOver: {{colors.surface_container.default.hex}}99;

    // Small close button
    smallCloseIconFg: {{colors.on_surface_variant.default.hex}};
    smallCloseIconFgOver: {{colors.on_surface.default.hex}};

    // Radial progress
    radialFg: {{colors.primary.default.hex}};
    radialBg: {{colors.surface_container.default.hex}};

    // Placeholder
    placeholderFg: {{colors.on_surface_variant.default.hex}}99;
    placeholderFgActive: {{colors.on_surface_variant.default.hex}};

    // Input
    inputBorderFg: {{colors.outline.default.hex}};

    // Filter checkbox
    filterInputBorderFg: {{colors.primary.default.hex}};

    // Check/radio
    checkboxFg: {{colors.outline.default.hex}};

    // Slider
    sliderBgInactive: {{colors.surface_container_highest.default.hex}};
    sliderBgActive: {{colors.primary.default.hex}};

    // Tooltip
    tooltipBg: {{colors.inverse_surface.default.hex}};
    tooltipFg: {{colors.inverse_on_surface.default.hex}};
    tooltipBorderFg: {{colors.inverse_surface.default.hex}};

    // Title
    titleShadow: {{colors.shadow.default.hex}}00;
    titleBg: {{colors.surface.default.hex}};
    titleBgActive: {{colors.surface.default.hex}};
    titleButtonBg: {{colors.surface.default.hex}};
    titleButtonFg: {{colors.on_surface_variant.default.hex}};
    titleButtonBgOver: {{colors.surface_container.default.hex}};
    titleButtonFgOver: {{colors.on_surface.default.hex}};
    titleButtonBgActive: {{colors.surface_container_high.default.hex}};
    titleButtonFgActive: {{colors.on_surface.default.hex}};
    titleButtonBgActiveOver: {{colors.surface_container_highest.default.hex}};
    titleButtonFgActiveOver: {{colors.on_surface.default.hex}};
    titleButtonCloseBg: {{colors.surface.default.hex}};
    titleButtonCloseFg: {{colors.on_surface_variant.default.hex}};
    titleButtonCloseBgOver: {{colors.error_container.default.hex}};
    titleButtonCloseFgOver: {{colors.on_error_container.default.hex}};
    titleButtonCloseBgActive: {{colors.error.default.hex}};
    titleButtonCloseFgActive: {{colors.on_error.default.hex}};
    titleFg: {{colors.on_surface.default.hex}};
    titleFgActive: {{colors.on_surface.default.hex}};

    // Tray icon
    trayCounterBg: {{colors.error.default.hex}};
    trayCounterBgMute: {{colors.outline.default.hex}};
    trayCounterFg: {{colors.on_error.default.hex}};
    trayCounterBgMacInvert: {{colors.on_surface.default.hex}};
    trayCounterFgMacInvert: {{colors.surface.default.hex}};

    // Layers
    layerBg: {{colors.scrim.default.hex}}99;

    // Cancel icon
    cancelIconFg: {{colors.on_surface_variant.default.hex}};
    cancelIconFgOver: {{colors.on_surface.default.hex}};

    // Box
    boxBg: {{colors.surface_container.default.hex}};
    boxTextFg: {{colors.on_surface.default.hex}};
    boxTextFgGood: {{colors.tertiary.default.hex}};
    boxTextFgError: {{colors.error.default.hex}};
    boxTitleFg: {{colors.on_surface.default.hex}};
    boxSearchBg: {{colors.surface_container_low.default.hex}};
    boxTitleAdditionalFg: {{colors.on_surface_variant.default.hex}};
    boxTitleCloseFg: {{colors.on_surface_variant.default.hex}};
    boxTitleCloseFgOver: {{colors.on_surface.default.hex}};

    // Members
    membersAboutLimitFg: {{colors.on_surface_variant.default.hex}};

    // Contacts
    contactsBg: {{colors.surface.default.hex}};
    contactsBgOver: {{colors.surface_container.default.hex}};
    contactsNameFg: {{colors.on_surface.default.hex}};
    contactsStatusFg: {{colors.on_surface_variant.default.hex}};
    contactsStatusFgOver: {{colors.on_surface_variant.default.hex}};
    contactsStatusFgOnline: {{colors.primary.default.hex}};

    // Photos
    photoCropFadeBg: {{colors.scrim.default.hex}}cc;
    photoCropPointFg: {{colors.primary.default.hex}};

    // Intro
    introBg: {{colors.surface.default.hex}};
    introTitleFg: {{colors.on_surface.default.hex}};
    introDescriptionFg: {{colors.on_surface_variant.default.hex}};
    introErrorFg: {{colors.error.default.hex}};
    introCoverTopBg: {{colors.primary.default.hex}};
    introCoverBottomBg: {{colors.primary_container.default.hex}};
    introCoverIconsFg: {{colors.on_primary.default.hex}};
    introCoverPlaneTrace: {{colors.on_primary.default.hex}}66;
    introCoverPlaneInner: {{colors.on_primary_container.default.hex}};
    introCoverPlaneOuter: {{colors.primary.default.hex}};
    introCoverPlaneTop: {{colors.on_primary.default.hex}};

    // Dialogs
    dialogsMenuIconFg: {{colors.on_surface_variant.default.hex}};
    dialogsMenuIconFgOver: {{colors.on_surface.default.hex}};
    dialogsBg: {{colors.surface.default.hex}};
    dialogsNameFg: {{colors.on_surface.default.hex}};
    dialogsChatIconFg: {{colors.primary.default.hex}};
    dialogsDateFg: {{colors.on_surface_variant.default.hex}};
    dialogsTextFg: {{colors.on_surface_variant.default.hex}};
    dialogsTextFgService: {{colors.primary.default.hex}};
    dialogsDraftFg: {{colors.error.default.hex}};
    dialogsVerifiedIconBg: {{colors.primary.default.hex}};
    dialogsVerifiedIconFg: {{colors.on_primary.default.hex}};
    dialogsSendingIconFg: {{colors.primary.default.hex}};
    dialogsSentIconFg: {{colors.primary.default.hex}};
    dialogsUnreadBg: {{colors.primary.default.hex}};
    dialogsUnreadBgMuted: {{colors.outline.default.hex}};
    dialogsUnreadFg: {{colors.on_primary.default.hex}};
    dialogsBgOver: {{colors.surface_container.default.hex}};
    dialogsBgActive: {{colors.primary_container.default.hex}};
    dialogsNameFgOver: {{colors.on_surface.default.hex}};
    dialogsChatIconFgOver: {{colors.primary.default.hex}};
    dialogsDateFgOver: {{colors.on_surface_variant.default.hex}};
    dialogsTextFgOver: {{colors.on_surface_variant.default.hex}};
    dialogsTextFgServiceOver: {{colors.primary.default.hex}};
    dialogsDraftFgOver: {{colors.error.default.hex}};
    dialogsVerifiedIconBgOver: {{colors.primary.default.hex}};
    dialogsVerifiedIconFgOver: {{colors.on_primary.default.hex}};
    dialogsSendingIconFgOver: {{colors.primary.default.hex}};
    dialogsSentIconFgOver: {{colors.primary.default.hex}};
    dialogsUnreadBgOver: {{colors.primary.default.hex}};
    dialogsUnreadBgMutedOver: {{colors.outline.default.hex}};
    dialogsUnreadFgOver: {{colors.on_primary.default.hex}};
    dialogsNameFgActive: {{colors.on_primary_container.default.hex}};
    dialogsChatIconFgActive: {{colors.on_primary_container.default.hex}};
    dialogsDateFgActive: {{colors.on_primary_container.default.hex}}cc;
    dialogsTextFgActive: {{colors.on_primary_container.default.hex}}cc;
    dialogsTextFgServiceActive: {{colors.on_primary_container.default.hex}};
    dialogsDraftFgActive: {{colors.error.default.hex}};
    dialogsVerifiedIconBgActive: {{colors.on_primary_container.default.hex}};
    dialogsVerifiedIconFgActive: {{colors.primary_container.default.hex}};
    dialogsSendingIconFgActive: {{colors.on_primary_container.default.hex}};
    dialogsSentIconFgActive: {{colors.on_primary_container.default.hex}};
    dialogsUnreadBgActive: {{colors.on_primary_container.default.hex}};
    dialogsUnreadBgMutedActive: {{colors.on_primary_container.default.hex}}99;
    dialogsUnreadFgActive: {{colors.primary_container.default.hex}};
    dialogsForwardBg: {{colors.primary.default.hex}};
    dialogsForwardFg: {{colors.on_primary.default.hex}};

    // Search
    searchedBarBg: {{colors.surface_container.default.hex}};
    searchedBarFg: {{colors.on_surface_variant.default.hex}};

    // History
    topBarBg: {{colors.surface.default.hex}};

    // Emoji panel
    emojiPanBg: {{colors.surface_container.default.hex}};
    emojiPanCategories: {{colors.surface_container_low.default.hex}};
    emojiPanHeaderFg: {{colors.on_surface_variant.default.hex}};
    emojiPanHeaderBg: {{colors.surface_container.default.hex}};
    emojiIconFg: {{colors.on_surface_variant.default.hex}};
    emojiIconFgActive: {{colors.primary.default.hex}};

    // Sticker panel
    stickerPanHeaderFg: {{colors.on_surface_variant.default.hex}};
    stickerPanHeaderBg: {{colors.surface_container.default.hex}};
    stickerPreviewBg: {{colors.surface_container.default.hex}};

    // History
    historyTextInFg: {{colors.on_surface.default.hex}};
    historyTextInFgSelected: {{colors.on_surface.default.hex}};
    historyTextOutFg: {{colors.on_primary_container.default.hex}};
    historyTextOutFgSelected: {{colors.on_primary_container.default.hex}};
    historyLinkInFg: {{colors.primary.default.hex}};
    historyLinkInFgSelected: {{colors.primary.default.hex}};
    historyLinkOutFg: {{colors.on_primary_container.default.hex}};
    historyLinkOutFgSelected: {{colors.on_primary_container.default.hex}};
    historyFileNameInFg: {{colors.on_surface.default.hex}};
    historyFileNameInFgSelected: {{colors.on_surface.default.hex}};
    historyFileNameOutFg: {{colors.on_primary_container.default.hex}};
    historyFileNameOutFgSelected: {{colors.on_primary_container.default.hex}};
    historyOutIconFg: {{colors.primary.default.hex}};
    historyOutIconFgSelected: {{colors.primary.default.hex}};
    historyIconFgInverted: {{colors.on_primary.default.hex}};
    historySendingOutIconFg: {{colors.primary.default.hex}};
    historySendingInIconFg: {{colors.primary.default.hex}};
    historySendingInvertedIconFg: {{colors.on_primary.default.hex}};
    historyUnreadBarBg: {{colors.surface_container_high.default.hex}};
    historyUnreadBarBorder: {{colors.surface_container_high.default.hex}};
    historyUnreadBarFg: {{colors.on_surface_variant.default.hex}};
    historyForwardChooseBg: {{colors.scrim.default.hex}}99;
    historyForwardChooseFg: {{colors.inverse_on_surface.default.hex}};
    historyPeer1NameFg: {{colors.error.default.hex}};
    historyPeer1NameFgSelected: {{colors.error.default.hex}};
    historyPeer1UserpicBg: {{colors.error_container.default.hex}};
    historyPeer2NameFg: {{colors.tertiary.default.hex}};
    historyPeer2NameFgSelected: {{colors.tertiary.default.hex}};
    historyPeer2UserpicBg: {{colors.tertiary_container.default.hex}};
    historyPeer3NameFg: {{colors.secondary.default.hex}};
    historyPeer3NameFgSelected: {{colors.secondary.default.hex}};
    historyPeer3UserpicBg: {{colors.secondary_container.default.hex}};
    historyPeer4NameFg: {{colors.primary.default.hex}};
    historyPeer4NameFgSelected: {{colors.primary.default.hex}};
    historyPeer4UserpicBg: {{colors.primary_container.default.hex}};
    historyPeer5NameFg: {{colors.tertiary.default.hex}};
    historyPeer5NameFgSelected: {{colors.tertiary.default.hex}};
    historyPeer5UserpicBg: {{colors.tertiary_container.default.hex}};
    historyPeer6NameFg: {{colors.error.default.hex}};
    historyPeer6NameFgSelected: {{colors.error.default.hex}};
    historyPeer6UserpicBg: {{colors.error_container.default.hex}};
    historyPeer7NameFg: {{colors.secondary.default.hex}};
    historyPeer7NameFgSelected: {{colors.secondary.default.hex}};
    historyPeer7UserpicBg: {{colors.secondary_container.default.hex}};
    historyPeer8NameFg: {{colors.primary.default.hex}};
    historyPeer8NameFgSelected: {{colors.primary.default.hex}};
    historyPeer8UserpicBg: {{colors.primary_container.default.hex}};
    historyPeerUserpicFg: {{colors.on_primary_container.default.hex}};
    historyScrollBarBg: {{colors.on_surface_variant.default.hex}}66;
    historyScrollBarBgOver: {{colors.on_surface_variant.default.hex}}99;
    historyScrollBg: {{colors.surface_container.default.hex}}66;
    historyScrollBgOver: {{colors.surface_container.default.hex}}99;

    // Message bubble
    msgInBg: {{colors.surface_container.default.hex}};
    msgInBgSelected: {{colors.surface_container_highest.default.hex}};
    msgOutBg: {{colors.primary_container.default.hex}};
    msgOutBgSelected: {{colors.primary.default.hex}}44;
    msgSelectOverlay: {{colors.primary.default.hex}}33;
    msgStickerOverlay: {{colors.primary.default.hex}}33;
    msgInServiceFg: {{colors.primary.default.hex}};
    msgInServiceFgSelected: {{colors.primary.default.hex}};
    msgOutServiceFg: {{colors.on_primary_container.default.hex}};
    msgOutServiceFgSelected: {{colors.on_primary_container.default.hex}};
    msgInShadow: {{colors.shadow.default.hex}}18;
    msgInShadowSelected: {{colors.shadow.default.hex}}22;
    msgOutShadow: {{colors.shadow.default.hex}}18;
    msgOutShadowSelected: {{colors.shadow.default.hex}}22;
    msgInDateFg: {{colors.on_surface_variant.default.hex}};
    msgInDateFgSelected: {{colors.on_surface_variant.default.hex}};
    msgOutDateFg: {{colors.on_primary_container.default.hex}}cc;
    msgOutDateFgSelected: {{colors.on_primary_container.default.hex}}cc;
    msgServiceFg: {{colors.inverse_on_surface.default.hex}};
    msgServiceBg: {{colors.inverse_surface.default.hex}}cc;
    msgServiceBgSelected: {{colors.inverse_surface.default.hex}};
    msgInReplyBarColor: {{colors.primary.default.hex}};
    msgInReplyBarSelColor: {{colors.primary.default.hex}};
    msgOutReplyBarColor: {{colors.on_primary_container.default.hex}};
    msgOutReplyBarSelColor: {{colors.on_primary_container.default.hex}};
    msgImgReplyBarColor: {{colors.on_primary.default.hex}};
    msgInMonoFg: {{colors.tertiary.default.hex}};
    msgInMonoFgSelected: {{colors.tertiary.default.hex}};
    msgOutMonoFg: {{colors.on_tertiary_container.default.hex}};
    msgOutMonoFgSelected: {{colors.on_tertiary_container.default.hex}};
    msgDateImgFg: {{colors.on_primary.default.hex}};
    msgDateImgBg: {{colors.scrim.default.hex}}99;
    msgDateImgBgOver: {{colors.scrim.default.hex}}cc;
    msgDateImgBgSelected: {{colors.primary.default.hex}}cc;
    msgFileThumbLinkInFg: {{colors.primary.default.hex}};
    msgFileThumbLinkInFgSelected: {{colors.primary.default.hex}};
    msgFileThumbLinkOutFg: {{colors.on_primary_container.default.hex}};
    msgFileThumbLinkOutFgSelected: {{colors.on_primary_container.default.hex}};
    msgFileInBg: {{colors.primary.default.hex}};
    msgFileInBgOver: {{colors.primary_container.default.hex}};
    msgFileInBgSelected: {{colors.primary.default.hex}};
    msgFileOutBg: {{colors.on_primary_container.default.hex}};
    msgFileOutBgOver: {{colors.on_primary_container.default.hex}}cc;
    msgFileOutBgSelected: {{colors.on_primary_container.default.hex}};

    // Sent message checks
    msgFile1Bg: {{colors.primary.default.hex}};
    msgFile1BgDark: {{colors.primary.default.hex}};
    msgFile1BgOver: {{colors.primary_container.default.hex}};
    msgFile1BgSelected: {{colors.primary.default.hex}};
    msgFile2Bg: {{colors.tertiary.default.hex}};
    msgFile2BgDark: {{colors.tertiary.default.hex}};
    msgFile2BgOver: {{colors.tertiary_container.default.hex}};
    msgFile2BgSelected: {{colors.tertiary.default.hex}};
    msgFile3Bg: {{colors.error.default.hex}};
    msgFile3BgDark: {{colors.error.default.hex}};
    msgFile3BgOver: {{colors.error_container.default.hex}};
    msgFile3BgSelected: {{colors.error.default.hex}};
    msgFile4Bg: {{colors.secondary.default.hex}};
    msgFile4BgDark: {{colors.secondary.default.hex}};
    msgFile4BgOver: {{colors.secondary_container.default.hex}};
    msgFile4BgSelected: {{colors.secondary.default.hex}};

    // Compose
    historyComposeAreaBg: {{colors.surface.default.hex}};
    historyComposeAreaFg: {{colors.on_surface.default.hex}};
    historyComposeAreaFgService: {{colors.primary.default.hex}};
    historyComposeIconFg: {{colors.on_surface_variant.default.hex}};
    historyComposeIconFgOver: {{colors.on_surface.default.hex}};
    historySendIconFg: {{colors.primary.default.hex}};
    historySendIconFgOver: {{colors.primary_container.default.hex}};
    historyPinnedBg: {{colors.surface_container.default.hex}};
    historyReplyBg: {{colors.surface_container.default.hex}};
    historyReplyIconFg: {{colors.primary.default.hex}};
    historyReplyCancelFg: {{colors.on_surface_variant.default.hex}};
    historyReplyCancelFgOver: {{colors.on_surface.default.hex}};

    // History message actions
    historyToDownBg: {{colors.surface_container.default.hex}};
    historyToDownBgOver: {{colors.surface_container_high.default.hex}};
    historyToDownBgRipple: {{colors.surface_container_highest.default.hex}};
    historyToDownFg: {{colors.on_surface_variant.default.hex}};
    historyToDownFgOver: {{colors.on_surface.default.hex}};
    historyToDownShadow: {{colors.shadow.default.hex}}66;

    // Overview
    overviewCheckBg: {{colors.primary.default.hex}}cc;
    overviewCheckBgActive: {{colors.primary.default.hex}};
    overviewCheckBgHover: {{colors.primary_container.default.hex}};
    overviewCheckFg: {{colors.on_primary.default.hex}};
    overviewCheckFgActive: {{colors.on_primary.default.hex}};
    overviewPhotoSelectOverlay: {{colors.scrim.default.hex}}66;

    // Profile
    profileStatusFgOver: {{colors.on_surface_variant.default.hex}};
    profileVerifiedCheckBg: {{colors.primary.default.hex}};
    profileVerifiedCheckFg: {{colors.on_primary.default.hex}};
    profileAdminStartFg: {{colors.secondary.default.hex}};
    profileAdminStarFgOver: {{colors.secondary.default.hex}};
    profileOtherAdminStarFg: {{colors.outline.default.hex}};
    profileOtherAdminStarFgOver: {{colors.outline.default.hex}};

    // Notifications
    notificationsBoxMonitorFg: {{colors.on_surface.default.hex}};
    notificationsBoxScreenBg: {{colors.surface_container_low.default.hex}};
    notificationSampleUserpicFg: {{colors.primary.default.hex}};
    notificationSampleCloseFg: {{colors.on_surface_variant.default.hex}};
    notificationSampleTextFg: {{colors.on_surface_variant.default.hex}};
    notificationSampleNameFg: {{colors.on_surface.default.hex}};

    // Changelog
    changelogCloseFg: {{colors.on_surface_variant.default.hex}};
    changelogCloseFgOver: {{colors.on_surface.default.hex}};

    // Main menu
    mainMenuBg: {{colors.surface.default.hex}};
    mainMenuCoverBg: {{colors.primary_container.default.hex}};
    mainMenuCoverFg: {{colors.on_primary_container.default.hex}};
    mainMenuCloudFg: {{colors.primary.default.hex}};
    mainMenuCloudBg: {{colors.surface_container.default.hex}};

    // Media
    mediaInFg: {{colors.on_surface_variant.default.hex}};
    mediaInFgSelected: {{colors.on_surface_variant.default.hex}};
    mediaOutFg: {{colors.on_primary_container.default.hex}}cc;
    mediaOutFgSelected: {{colors.on_primary_container.default.hex}}cc;

    // Media player
    mediaPlayerBg: {{colors.surface.default.hex}};
    mediaPlayerActiveFg: {{colors.primary.default.hex}};
    mediaPlayerInactiveFg: {{colors.outline.default.hex}};
    mediaPlayerDisabledFg: {{colors.outline_variant.default.hex}};

    // Media view
    mediaviewFileBg: {{colors.surface_container.default.hex}};
    mediaviewFileNameFg: {{colors.on_surface.default.hex}};
    mediaviewFileSizeFg: {{colors.on_surface_variant.default.hex}};
    mediaviewFileRedCornerFg: {{colors.error.default.hex}};
    mediaviewFileYellowCornerFg: {{colors.secondary.default.hex}};
    mediaviewFileGreenCornerFg: {{colors.tertiary.default.hex}};
    mediaviewFileBlueCornerFg: {{colors.primary.default.hex}};
    mediaviewFileExtFg: {{colors.on_primary.default.hex}};
    mediaviewMenuBg: {{colors.surface_container.default.hex}};
    mediaviewMenuBgOver: {{colors.surface_container_high.default.hex}};
    mediaviewMenuFg: {{colors.on_surface.default.hex}};
    mediaviewBg: {{colors.scrim.default.hex}}ee;
    mediaviewVideoBg: {{colors.surface_dim.default.hex}};
    mediaviewControlBg: {{colors.surface_container.default.hex}}cc;
    mediaviewControlFg: {{colors.on_surface.default.hex}};
    mediaviewCaptionBg: {{colors.surface_container.default.hex}}cc;
    mediaviewCaptionFg: {{colors.on_surface.default.hex}};
    mediaviewTextLinkFg: {{colors.primary.default.hex}};
    mediaviewSaveMsgBg: {{colors.inverse_surface.default.hex}};
    mediaviewSaveMsgFg: {{colors.inverse_on_surface.default.hex}};
    mediaviewPlaybackActive: {{colors.primary.default.hex}};
    mediaviewPlaybackInactive: {{colors.outline.default.hex}};
    mediaviewPlaybackActiveOver: {{colors.primary_container.default.hex}};
    mediaviewPlaybackInactiveOver: {{colors.outline_variant.default.hex}};
    mediaviewPlaybackProgressFg: {{colors.on_surface.default.hex}};
    mediaviewPlaybackIconFg: {{colors.on_surface.default.hex}};
    mediaviewPlaybackIconFgOver: {{colors.primary.default.hex}};
    mediaviewTransparentBg: {{colors.surface_dim.default.hex}};
    mediaviewTransparentFg: {{colors.outline.default.hex}};

    // Calls
    callBg: {{colors.surface.default.hex}};
    callNameFg: {{colors.on_surface.default.hex}};
    callFingerprintBg: {{colors.surface_container.default.hex}};
    callStatusFg: {{colors.on_surface_variant.default.hex}};
    callIconFg: {{colors.primary.default.hex}};
    callAnswerBg: {{colors.tertiary.default.hex}};
    callAnswerRipple: {{colors.tertiary_container.default.hex}};
    callAnswerBgOuter: {{colors.tertiary.default.hex}}44;
    callHangupBg: {{colors.error.default.hex}};
    callHangupRipple: {{colors.error_container.default.hex}};
    callCancelBg: {{colors.surface_container.default.hex}};
    callCancelFg: {{colors.on_surface.default.hex}};
    callCancelRipple: {{colors.surface_container_high.default.hex}};
    callMuteRipple: {{colors.surface_container_highest.default.hex}};

    // Import
    importOptionBg: {{colors.surface_container.default.hex}};
    importOptionBgHover: {{colors.surface_container_high.default.hex}};
    importOptionTitle: {{colors.on_surface.default.hex}};
    importOptionInfo: {{colors.on_surface_variant.default.hex}};
  '';

  # TOML config entries for matugen
  matugenConfigExtra = ''
    [templates.zed-dark]
    input_path = '/home/zeev/.config/matugen/templates/zed-colors.json'
    output_path = '/home/zeev/.config/zed/themes/matugen.json'

    [templates.materialgram]
    input_path = '/home/zeev/.config/matugen/templates/materialgram.tdesktop-theme'
    output_path = '/home/zeev/.local/share/TelegramDesktop/tdata/matugen.tdesktop-theme'
  '';
in {
  # Install templates to matugen templates directory
  xdg.configFile = {
    "matugen/templates/zed-colors.json" = {
      source = zedTemplate;
    };
    "matugen/templates/materialgram.tdesktop-theme" = {
      source = materialgramTemplate;
    };
  };

  # Create a script that appends our template config to matugen's config.toml
  # This runs after DMS generates its config
  home.activation.matugenTemplates = lib.hm.dag.entryAfter ["writeBoundary"] ''
    # Wait for DMS to create the config, then append our templates
    CONFIG_FILE="$HOME/.config/matugen/config.toml"
    MARKER="# Custom templates from nix-config"

    if [ -f "$CONFIG_FILE" ]; then
      # Check if our custom config is already present
      if ! grep -q "$MARKER" "$CONFIG_FILE"; then
        echo "" >> "$CONFIG_FILE"
        echo "$MARKER" >> "$CONFIG_FILE"
        cat >> "$CONFIG_FILE" << 'MATUGEN_EOF'
    ${matugenConfigExtra}
    MATUGEN_EOF
      fi
    fi
  '';
}
