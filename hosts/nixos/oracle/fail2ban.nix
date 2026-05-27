{config, ...}: {
  services.fail2ban = {
    enable = true;
    maxretry = 5;
    bantime = "1h";

    bantime-increment = {
      enable = true;
      multipliers = "2 4 8 16 32 64";
      maxtime = "168h";
      overalljails = true;
    };

    ignoreIP = [
      "127.0.0.0/8"
      "100.64.0.0/10" # Tailscale CGNAT
    ];

    jails.sshd.settings = {
      enabled = true;
      maxretry = 3;
      bantime = "24h";
      findtime = "10m";
    };
  };

  # fail2ban SSH jail needs openssh enabled — already set in default.nix
  # CrowdSec handles Caddy log parsing, so no caddy jail here
}
