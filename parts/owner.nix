# Owner metadata — non-secret values used for flake-level wiring.
# Secret-backed values (API keys, etc.) stay in NixOS module options via sops.
_: {
  meta.owner = {
    username = "zeev";
    email = "redacted@example.com";
    gitUsername = "4rmcyt";
    gitSigningKey = "D85B52C9288A138E";
    domain = "example.com";
    timezone = "America/Edmonton";
    locale = "en_US.UTF-8";
    gateway = "192.168.1.254";
    homeserverLan = "192.168.1.165";
    desktopLan = "192.168.1.118";
    desktopWifi = "192.168.1.239";
    matebookWifi = "192.168.1.132";
  };
}
