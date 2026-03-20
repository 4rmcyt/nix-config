{config, ...}: {
  systemd.tmpfiles.rules = [
    "d /var/log/cowrie 0777 root root -"
    "d /var/lib/cowrie/downloads 0777 root root -"
  ];

  # API keys injected from sops-encrypted dotenv (COWRIE_OUTPUT_ABUSEIPDB_API_KEY, COWRIE_OUTPUT_VIRUSTOTAL_API_KEY)
  sops.secrets.cowrie_env = {
    sopsFile = ../../../secrets/cowrie.env;
    format = "dotenv";
  };

  # ── OCI container ──────────────────────────────────────────────────────────
  # Config via env vars — Cowrie checks COWRIE_<SECTION>_<KEY> before config files.
  # Real sshd moved to 2222 (hosts/nixos/homeserver/default.nix).
  # Podman backend set in modules/containers/default.nix.
  virtualisation.oci-containers.containers.cowrie = {
    autoStart = true;
    image = "docker.io/cowrie/cowrie:latest";
    ports = [
      "22:2222/tcp" # SSH honeypot
      "23:2223/tcp" # Telnet honeypot
      "9001:9001/tcp" # Prometheus metrics
    ];
    volumes = [
      "/var/log/cowrie:/var/log/cowrie"
      "/var/lib/cowrie/downloads:/cowrie/cowrie-git/var/lib/cowrie/downloads"
      "/etc/cowrie/userdb.txt:/cowrie/cowrie-git/etc/userdb.txt:ro"
      "/etc/cowrie/honeyfs/etc/motd:/cowrie/cowrie-git/honeyfs/etc/motd:ro"
      "/etc/cowrie/honeyfs/etc/issue.net:/cowrie/cowrie-git/honeyfs/etc/issue.net:ro"
      "/etc/cowrie/honeyfs/etc/passwd:/cowrie/cowrie-git/honeyfs/etc/passwd:ro"
      # dump_path for AbuseIPDB output plugin (crashes without a writable path)
      "/var/log/cowrie:/var/log/cowrie-abuseipdb"
    ];
    environment = {
      COWRIE_HONEYPOT_HOSTNAME = "ubuntu-srv";
      COWRIE_HONEYPOT_LOG_PATH = "/var/log/cowrie";
      COWRIE_HONEYPOT_DOWNLOAD_PATH = "/cowrie/cowrie-git/var/lib/cowrie/downloads";

      # Mimics Ubuntu 22.04 LTS OpenSSH
      COWRIE_SSH_VERSION = "SSH-2.0-OpenSSH_8.9p1 Ubuntu-3ubuntu0.6";
      COWRIE_SSH_LISTEN_ENDPOINTS = "tcp:2222:interface=0.0.0.0";

      COWRIE_TELNET_ENABLED = "true";
      COWRIE_TELNET_LISTEN_ENDPOINTS = "tcp:2223:interface=0.0.0.0";

      COWRIE_SHELL_KERNEL_VERSION = "5.15.0-91-generic";

      COWRIE_OUTPUT_JSONLOG_ENABLED = "true";
      COWRIE_OUTPUT_JSONLOG_LOGFILE = "/var/log/cowrie/cowrie.json";

      COWRIE_OUTPUT_PROMETHEUS_ENABLED = "yes";
      COWRIE_OUTPUT_PROMETHEUS_PORT = "9001";

      COWRIE_OUTPUT_ABUSEIPDB_ENABLED = "true";
      COWRIE_OUTPUT_ABUSEIPDB_DUMP_PATH = "/var/log/cowrie-abuseipdb";
      COWRIE_OUTPUT_ABUSEIPDB_CATEGORIES = "18,22"; # 18=Brute-Force, 22=SSH
      COWRIE_OUTPUT_ABUSEIPDB_THRESHOLD = "1";
      COWRIE_OUTPUT_ABUSEIPDB_REREPORT_AFTER = "24"; # hours

      COWRIE_OUTPUT_VIRUSTOTAL_ENABLED = "true";
      COWRIE_OUTPUT_VIRUSTOTAL_UPLOAD = "true";
    };
    environmentFiles = [config.sops.secrets.cowrie_env.path];
  };

  # ── Fake credential list ───────────────────────────────────────────────────
  # format: username:uid:password — uid ignored, use 0 for compat
  environment.etc."cowrie/userdb.txt" = {
    mode = "0644";
    text = ''
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

  environment.etc."cowrie/honeyfs/etc/issue.net" = {
    mode = "0644";
    text = "Ubuntu 22.04.3 LTS\n";
  };

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
  # Promotes src_ip to meta.source_ip so the existing postoverflow whitelist applies.
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
              expression: "ToString(evt.Unmarshaled.cowrie.src_ip)"
      statics:
        - meta: source_ip
          expression: "ToString(evt.Unmarshaled.cowrie.src_ip)"
    '';
  };

  # ── CrowdSec scenario ─────────────────────────────────────────────────────
  # type: trigger — one honeypot touch = immediate alert.
  # blackhole: 1m — prevents alert flood from the same IP.
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
