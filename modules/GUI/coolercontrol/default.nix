{
  programs.coolercontrol.enable = true;

  # `C` copies only if the target doesn't already exist — never clobbers live GUI
  # changes. Deliberately NOT restored: TLS keypair (daemon regenerates it) and .passwd
  # (reset once via UI instead of committing credential material). See
  # docs/bios-desktop-settings.md section 8 for the fan-curve rationale.
  systemd.tmpfiles.rules = [
    "C /etc/coolercontrol/config.toml 0644 root root - ${./config.toml}"
    "C /etc/coolercontrol/alerts.json 0644 root root - ${./alerts.json}"
  ];
}
