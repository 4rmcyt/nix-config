{
  config,
  lib,
  ...
}:
{
  environment.systemPackages = [
    config.programs.browsing.chromium.package
  ];

  programs.chromium = {
    enable = lib.mkDefault true;
    extraOpts = {
      "AudioSandboxEnabled" = false;
      "AutofillAddressEnabled" = false;
      "AutofillCreditCardEnabled" = false;
      "BlockThirdPartyCookies" = true;
      "BraveAIChatEnabled" = 0; # Disable Brave AI Chat
      "BraveNewsDisabled" = 1; # Disable Brave News
      "BraveRewardsDisabled" = 1; # Disable Brave Rewards
      "BraveTalkDisabled" = 1; # Disable Brave Talk
      "BraveVPNDisabled" = 1; # Disable Brave VPN
      "BraveWalletDisabled" = 1; # Disable Brave Wallet
      "DefaultSearchProviderEnabled" = true;
      "RestoreOnStartup" = 4; # Restore specified pages
      "RestoreOnStartupURLs" = [ "https://start.v3rm1n.dev" ];
      "MetricsReportingEnabled" = false;
      "PasswordManagerEnabled" = false;
      "SafeBrowsingExtendedReportingEnabled" = false;
    };
    extensions = [
      "nngceckbapebfimnlniiiahkandclblb" # Bitwarden
      "enamippconapkdmgfgjchkhakpfinmaj" # DeArrow
      "oldceeleldhonbafppcapldpdifcinji" # LanguageTool
      "bggfcpfjbdkhfhfmkjpbhnkhnpjjeomc" # Material Icons for GitHub
      "pkehgijcmpdhfbdbbnkijodmdjhbjlgp" # Privacy Badger
      #"ghmbeldphafepmbegfdlkpapadhbakde" # Proton Pass
      "gebbhagfogifgggkldgodflihgfeippi" # Return YouTube Dislike
      #"cjpalhdlnbpafiamejdnhcphjbkeiagm" # uBlock Origin
      "ponfpcnoihfmfllpaingbgckeeldkhle" # YouTube Enhancer
    ];
  };
}
