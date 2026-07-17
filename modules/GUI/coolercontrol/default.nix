{
  programs.coolercontrol.enable = true;

  # Restores the fan/pump control config (Profiles, Functions, device
  # settings) from a known-good snapshot committed in this module, in case
  # /etc/coolercontrol ever starts empty (fresh install, wiped state).
  # `C` = copy only if the target doesn't already exist — never clobbers
  # live changes made through the GUI. Device UIDs in config.toml are
  # sha256 hashes of stable hardware characteristics, so they re-match the
  # same physical devices after a reinstall.
  #
  # Deliberately NOT restored: coolercontrol.crt/.key (TLS keypair, the
  # daemon regenerates these itself if missing) and .passwd (admin
  # password hash — reset it once via the UI on a fresh install instead of
  # committing credential material to the repo).
  #
  # See docs/bios-desktop-settings.md section 8 for the full fan-curve
  # reference and rationale behind these values.
  systemd.tmpfiles.rules = [
    "C /etc/coolercontrol/config.toml 0644 root root - ${./config.toml}"
    "C /etc/coolercontrol/alerts.json 0644 root root - ${./alerts.json}"
  ];
}
