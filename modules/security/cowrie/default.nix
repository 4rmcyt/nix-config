_: {
  # ── Log directory ──────────────────────────────────────────────────────────
  # Owned root:crowdsec so CrowdSec can tail without running as root.
  # crowdsec group exists because ./crowdsec is imported first in security/default.nix.
  systemd.tmpfiles.rules = [
    "d /var/log/cowrie 0750 root crowdsec -"
  ];

  # ── Cowrie config ──────────────────────────────────────────────────────────
  # hostname = "srv" — generic, does not reveal real hostname.
  # version string mimics Ubuntu OpenSSH (must NOT match real server version).
  # listen_endpoints binds inside the container on 2222 → mapped to host port 22.
  environment.etc."cowrie/cowrie.cfg" = {
    mode = "0644";
    text = ''
      [honeypot]
      hostname = srv
      log_path = /var/log/cowrie
      download_path = /var/lib/cowrie/dl

      [ssh]
      version = SSH-2.0-OpenSSH_8.9p1 Ubuntu-3ubuntu0.6
      listen_endpoints = tcp:2222:interface=0.0.0.0

      [output_jsonlog]
      enabled = true
      logfile = /var/log/cowrie/cowrie.json
    '';
  };

  # ── OCI container ──────────────────────────────────────────────────────────
  # Real sshd is moved to port 2222 in hosts/nixos/homeserver/default.nix.
  # Podman backend is set in modules/containers/default.nix.
  virtualisation.oci-containers.containers.cowrie = {
    autoStart = true;
    image = "docker.io/cowrie/cowrie:latest";
    ports = ["22:2222/tcp"];
    volumes = [
      "/var/log/cowrie:/var/log/cowrie"
      "/etc/cowrie/cowrie.cfg:/cowrie/cowrie-git/etc/cowrie.cfg:ro"
    ];
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
