_: {
  # ── Log directory ──────────────────────────────────────────────────────────
  # Owned root:crowdsec so CrowdSec can tail without running as root.
  # crowdsec group exists because ./crowdsec is imported first in security/default.nix.
  systemd.tmpfiles.rules = [
    # 0755 + group/other write: cowrie container (uid 1000) writes, crowdsec reads
    "d /var/log/cowrie 0777 root root -"
  ];

  # ── OCI container ──────────────────────────────────────────────────────────
  # Config via env vars — avoids the anonymous volume shadow on /cowrie/cowrie-git/etc.
  # Cowrie's EnvironmentConfigParser checks COWRIE_<SECTION>_<KEY> before config files.
  # Log path: bind-mount host /var/log/cowrie → container /var/log/cowrie (absolute path,
  # outside the /cowrie/cowrie-git/var anonymous volume, so no shadowing).
  # Real sshd is moved to port 2222 in hosts/nixos/homeserver/default.nix.
  # Podman backend is set in modules/containers/default.nix.
  virtualisation.oci-containers.containers.cowrie = {
    autoStart = true;
    image = "docker.io/cowrie/cowrie:latest";
    ports = ["22:2222/tcp" "9001:9001/tcp"];
    volumes = [
      "/var/log/cowrie:/var/log/cowrie"
    ];
    environment = {
      COWRIE_HONEYPOT_HOSTNAME = "srv";
      COWRIE_HONEYPOT_LOG_PATH = "/var/log/cowrie";
      COWRIE_SSH_VERSION = "SSH-2.0-OpenSSH_8.9p1 Ubuntu-3ubuntu0.6";
      COWRIE_SSH_LISTEN_ENDPOINTS = "tcp:2222:interface=0.0.0.0";
      COWRIE_OUTPUT_JSONLOG_ENABLED = "true";
      COWRIE_OUTPUT_JSONLOG_LOGFILE = "/var/log/cowrie/cowrie.json";
      COWRIE_OUTPUT_PROMETHEUS_ENABLED = "yes";
      COWRIE_OUTPUT_PROMETHEUS_PORT = "9001";
    };
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
