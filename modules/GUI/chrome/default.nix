{lib, ...}: {
  # Chrome managed policies — written to /etc/opt/chrome/policies/managed/
  # These cannot be overridden by the user in Chrome UI.
  environment.etc."opt/chrome/policies/managed/hardening.json".text = lib.generators.toJSON {} {
    # Account & sync
    BrowserSignin = 1;
    SyncDisabled = false;
    RestoreOnStartup = 1;

    # Privacy: disable telemetry & UMA reporting
    MetricsReportingEnabled = false;
    CloudReportingEnabled = false;

    # Privacy: SafeBrowsing standard only (enhanced sends URL hashes to Google)
    SafeBrowsingEnabled = true;
    SafeBrowsingProtectionLevel = 1;

    # Privacy: disable sending text to Google for spell-check
    SpellCheckServiceEnabled = false;

    # Security: DNS-over-HTTPS via NextDNS
    DnsOverHttpsMode = "automatic";
    DnsOverHttpsTemplates = "https://dns.nextdns.io/nextdns0";

    # Security: prevent internal IP leak via WebRTC
    WebRtcIPHandling = "default_public_interface_only";

    # Security: force HTTPS-only mode
    HttpsOnlyMode = "force_enabled";

    # Security: minimum TLS version
    SSLVersionMin = "tls1.2";

    # Security: block mixed content
    DefaultInsecureContentSetting = 2;
  };
}
