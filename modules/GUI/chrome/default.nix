{
  lib,
  config,
  ...
}: {
  # Chrome managed policies — written to /etc/opt/chrome/policies/managed/
  # These cannot be overridden by the user in Chrome UI.
  environment.etc."opt/chrome/policies/managed/hardening.json".text = lib.generators.toJSON {} {
    BrowserSignin = 1;
    SyncDisabled = false;
    RestoreOnStartup = 1;

    MetricsReportingEnabled = false;
    CloudReportingEnabled = false;

    # SafeBrowsing standard only (enhanced sends URL hashes to Google)
    SafeBrowsingEnabled = true;
    SafeBrowsingProtectionLevel = 1;

    SpellCheckServiceEnabled = false;

    DnsOverHttpsMode = "automatic";
    DnsOverHttpsTemplates = "https://dns.nextdns.io/${config.my.defaults.nextdnsProfileId}";

    # Prevents internal IP leak via WebRTC
    WebRtcIPHandling = "default_public_interface_only";

    HttpsOnlyMode = "force_enabled";

    SSLVersionMin = "tls1.2";

    DefaultInsecureContentSetting = 2;
  };
}
