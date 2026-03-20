{config, ...}: {
  # ── Log directory ──────────────────────────────────────────────────────────
  # 0777 so the cowrie container (uid 999) can write without running as root.
  # crowdsec reads the log via its acquisition config.
  systemd.tmpfiles.rules = [
    "d /var/log/cowrie 0777 root root -"
    # /var/lib/cowrie → /cowrie/cowrie-git/var inside container.
    # Downloads land at var/lib/cowrie/downloads relative to that mount point.
    "d /var/lib/cowrie/lib/cowrie/downloads 0777 root root -"
    "d /var/lib/cowrie/log/cowrie/tty 0777 root root -"
  ];

  # ── Sops secrets (API keys) ────────────────────────────────────────────────
  # secrets/cowrie.env is a sops-encrypted dotenv file containing:
  #   COWRIE_OUTPUT_ABUSEIPDB_API_KEY=<key>
  #   COWRIE_OUTPUT_VIRUSTOTAL_API_KEY=<key>
  sops.secrets.cowrie_env = {
    sopsFile = ../../../secrets/cowrie.env;
    format = "dotenv";
  };

  # ── OCI container ──────────────────────────────────────────────────────────
  # The Cowrie image declares VOLUME ["/cowrie/cowrie-git/etc", "/cowrie/cowrie-git/var"].
  # File-level bind mounts inside a VOLUME-declared directory are shadowed by the anonymous
  # volume Podman creates. Fix: mount the entire directory to replace the anonymous volume.
  # /etc/cowrie → /cowrie/cowrie-git/etc (contains userdb.txt + honeyfs/)
  # /var/lib/cowrie → /cowrie/cowrie-git/var (contains tty logs, downloads)
  # Real sshd is moved to port 2222 in hosts/nixos/homeserver/default.nix.
  # Podman backend is set in modules/containers/default.nix.
  virtualisation.oci-containers.containers.cowrie = {
    autoStart = true;
    image = "docker.io/cowrie/cowrie:latest";
    ports = [
      "22:2222/tcp" # SSH honeypot (real sshd moved to 2222)
      "23:2223/tcp" # Telnet honeypot
      "9001:9001/tcp" # Prometheus metrics
    ];
    volumes = [
      "/var/log/cowrie:/var/log/cowrie"
      # Mount entire dirs to override the image's anonymous VOLUMEs for these paths.
      # File-level bind mounts inside an image-declared VOLUME dir are shadowed — only
      # a full directory mount replaces the anonymous volume.
      "/etc/cowrie:/cowrie/cowrie-git/etc:ro"
      "/var/lib/cowrie:/cowrie/cowrie-git/var"
      # Fake /etc files served to attackers inside the fake shell.
      # honeyfs is at /cowrie/cowrie-git/honeyfs/ (outside the VOLUME dirs above).
      "/etc/cowrie/honeyfs/etc/motd:/cowrie/cowrie-git/honeyfs/etc/motd:ro"
      "/etc/cowrie/honeyfs/etc/issue.net:/cowrie/cowrie-git/honeyfs/etc/issue.net:ro"
      "/etc/cowrie/honeyfs/etc/passwd:/cowrie/cowrie-git/honeyfs/etc/passwd:ro"
      # AbuseIPDB dump dir (output_abuseipdb requires a writable dump_path)
      "/var/log/cowrie:/var/log/cowrie-abuseipdb"
    ];
    environment = {
      # ── Honeypot identity ──────────────────────────────────────────────────
      # Generic Ubuntu server identity — does NOT reveal real hostname/version.
      COWRIE_HONEYPOT_HOSTNAME = "ubuntu-srv";
      COWRIE_HONEYPOT_LOG_PATH = "/var/log/cowrie";
      COWRIE_HONEYPOT_DOWNLOAD_PATH = "/cowrie/cowrie-git/var/lib/cowrie/downloads"; # inside container

      # ── SSH listener ───────────────────────────────────────────────────────
      # Mimics Ubuntu 22.04 LTS OpenSSH — common enough to attract scanners.
      COWRIE_SSH_VERSION = "SSH-2.0-OpenSSH_8.9p1 Ubuntu-3ubuntu0.6";
      COWRIE_SSH_LISTEN_ENDPOINTS = "tcp:2222:interface=0.0.0.0";

      # ── Telnet listener ────────────────────────────────────────────────────
      COWRIE_TELNET_ENABLED = "true";
      COWRIE_TELNET_LISTEN_ENDPOINTS = "tcp:2223:interface=0.0.0.0";

      # ── Shell identity (shown to attacker in fake shell) ───────────────────
      COWRIE_SHELL_KERNEL_VERSION = "5.15.0-91-generic";

      # ── JSON log output ────────────────────────────────────────────────────
      COWRIE_OUTPUT_JSONLOG_ENABLED = "true";
      COWRIE_OUTPUT_JSONLOG_LOGFILE = "/var/log/cowrie/cowrie.json";

      # ── Prometheus metrics ─────────────────────────────────────────────────
      COWRIE_OUTPUT_PROMETHEUS_ENABLED = "yes";
      COWRIE_OUTPUT_PROMETHEUS_PORT = "9001";

      # ── AbuseIPDB reporting ────────────────────────────────────────────────
      # Reports attacker IPs automatically; dump_path required (crashes without it).
      COWRIE_OUTPUT_ABUSEIPDB_ENABLED = "true";
      COWRIE_OUTPUT_ABUSEIPDB_DUMP_PATH = "/var/log/cowrie-abuseipdb";
      COWRIE_OUTPUT_ABUSEIPDB_CATEGORIES = "18,22"; # 18=Brute-Force, 22=SSH
      COWRIE_OUTPUT_ABUSEIPDB_THRESHOLD = "1"; # Report after 1 event
      COWRIE_OUTPUT_ABUSEIPDB_REREPORT_AFTER = "24"; # Hours before re-reporting same IP

      # ── VirusTotal malware analysis ────────────────────────────────────────
      # Submits downloaded malware samples to VirusTotal for analysis.
      COWRIE_OUTPUT_VIRUSTOTAL_ENABLED = "true";
      COWRIE_OUTPUT_VIRUSTOTAL_UPLOAD = "true"; # Upload file content (not just hash)
    };
    # API keys from sops-encrypted dotenv file
    # (COWRIE_OUTPUT_ABUSEIPDB_API_KEY and COWRIE_OUTPUT_VIRUSTOTAL_API_KEY)
    environmentFiles = [config.sops.secrets.cowrie_env.path];
  };

  # ── Fake credential list ───────────────────────────────────────────────────
  # Format per line: username:password:status (success/failure/*)
  # Lines starting with # are comments.
  # Cowrie accepts any username/password not explicitly denied here.
  # Listed combinations always succeed (lures attackers into the fake shell).
  environment.etc."cowrie/userdb.txt" = {
    mode = "0644";
    text = ''
      # Cowrie credential database
      # format: username:uid:password  (uid ignored; use 0 for compat)
      # password: exact string, or * to match anything
      # Prefix password with ! to deny (attacker sees auth failure)
      #
      # Always accept common default credentials (attacker gets a shell)
      root:0:root
      root:0:toor
      root:0:123456
      root:0:password
      root:0:admin
      root:0:raspberry
      root:0:alpine
      admin:0:admin
      admin:0:password
      admin:0:123456
      ubuntu:0:ubuntu
      pi:0:raspberry
      pi:0:pi
      user:0:user
      guest:0:guest
      test:0:test
      support:0:support
      oracle:0:oracle
      postgres:0:postgres
      git:0:git
    '';
  };

  # ── Fake /etc/motd (shown after login in fake shell) ──────────────────────
  environment.etc."cowrie/honeyfs/etc/motd" = {
    mode = "0644";
    text = ''
      Welcome to Ubuntu 22.04.3 LTS (GNU/Linux 5.15.0-91-generic x86_64)

       * Documentation:  https://help.ubuntu.com
       * Management:     https://landscape.canonical.com
       * Support:        https://ubuntu.com/advantage

        System information as of Wed Mar 19 12:00:00 UTC 2026

        System load:  0.08              Processes:             142
        Usage of /:   45.2% of 19.6GB  Users logged in:       0
        Memory usage: 23%               IPv4 address for eth0: 10.0.2.15
        Swap usage:   0%

      0 updates can be applied immediately.

      Last login: Wed Mar 19 05:32:17 2026 from 10.0.0.1
    '';
  };

  # ── Fake /etc/issue.net (shown as pre-login SSH banner) ───────────────────
  environment.etc."cowrie/honeyfs/etc/issue.net" = {
    mode = "0644";
    text = "Ubuntu 22.04.3 LTS\n";
  };

  # ── Fake /etc/passwd (shown to `cat /etc/passwd` in fake shell) ───────────
  environment.etc."cowrie/honeyfs/etc/passwd" = {
    mode = "0644";
    text = ''
      root:x:0:0:root:/root:/bin/bash
      daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
      bin:x:2:2:bin:/bin:/usr/sbin/nologin
      sys:x:3:3:sys:/dev:/usr/sbin/nologin
      sync:x:4:65534:sync:/bin:/bin/sync
      games:x:5:60:games:/usr/games:/usr/sbin/nologin
      man:x:6:12:man:/var/cache/man:/usr/sbin/nologin
      lp:x:7:7:lp:/var/spool/lpd:/usr/sbin/nologin
      mail:x:8:8:mail:/var/mail:/usr/sbin/nologin
      news:x:9:9:news:/var/spool/news:/usr/sbin/nologin
      uucp:x:10:10:uucp:/var/spool/uucp:/usr/sbin/nologin
      proxy:x:13:13:proxy:/bin:/usr/sbin/nologin
      www-data:x:33:33:www-data:/var/www:/usr/sbin/nologin
      backup:x:34:34:backup:/var/backups:/usr/sbin/nologin
      list:x:38:38:Mailing List Manager:/var/list:/usr/sbin/nologin
      irc:x:39:39:ircd:/run/ircd:/usr/sbin/nologin
      gnats:x:41:41:Gnats Bug-Reporting System (admin):/var/lib/gnats:/usr/sbin/nologin
      nobody:x:65534:65534:nobody:/nonexistent:/usr/sbin/nologin
      _apt:x:100:65534::/nonexistent:/usr/sbin/nologin
      systemd-network:x:101:102:systemd Network Management,,,:/run/systemd:/usr/sbin/nologin
      systemd-resolve:x:102:103:systemd Resolver,,,:/run/systemd:/usr/sbin/nologin
      messagebus:x:103:104::/nonexistent:/usr/sbin/nologin
      systemd-timesync:x:104:105:systemd Time Synchronization,,,:/run/systemd:/usr/sbin/nologin
      sshd:x:105:65534::/run/sshd:/usr/sbin/nologin
      ubuntu:x:1000:1000:Ubuntu:/home/ubuntu:/bin/bash
    '';
  };

  # ── CrowdSec parser ────────────────────────────────────────────────────────
  # Parses Cowrie's JSON log format. Promotes src_ip to meta.source_ip so the
  # existing postoverflow whitelist (LAN/Tailscale/Cloudflare) applies automatically.
  environment.etc."crowdsec/parsers/s01-parse/cowrie.yaml" = {
    user = "crowdsec";
    group = "crowdsec";
    mode = "0640";
    text = ''
      name: crowdsecurity/cowrie
      description: "Parse Cowrie honeypot JSON events"
      filter: "evt.Line.Labels.type == 'cowrie'"
      onsuccess: next_stage
      nodes:
        - filter: "UnmarshalJSON(evt.Line.Raw, evt.Unmarshaled, 'cowrie') in [\"\", nil]"
          statics:
            - meta: log_type
              value: cowrie
            - meta: source_ip
              expression: "evt.Unmarshaled.cowrie.src_ip"
      statics:
        - meta: source_ip
          expression: "evt.Unmarshaled.cowrie.src_ip"
    '';
  };

  # ── CrowdSec scenario ─────────────────────────────────────────────────────
  # type: trigger — one event = one alert (no threshold needed for a honeypot).
  # blackhole: 1m — prevents alert flood from the same IP within a minute.
  # remediation: true — LAPI forwards to bouncers (Cloudflare WAF bans the IP).
  environment.etc."crowdsec/scenarios/cowrie-honeypot.yaml" = {
    user = "crowdsec";
    group = "crowdsec";
    mode = "0640";
    text = ''
      type: trigger
      name: crowdsecurity/cowrie-honeypot
      description: "Ban any IP that touches the SSH honeypot"
      filter: "evt.Meta.log_type == 'cowrie'"
      groupby: evt.Meta.source_ip
      blackhole: 1m
      labels:
        service: cowrie
        type: honeypot
        remediation: true
    '';
  };
}
