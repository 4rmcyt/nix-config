{
  config,
  lib,
  ...
}: let
  inherit (config.my.defaults) user domain;
in {
  sops.secrets = {
    ssh_private_key = {
      sopsFile = ../../../secrets/ssh.yaml;
      key = "ssh_private_key";
      mode = "0600";
      owner = user;
      group = "users";
      path = "/home/${user}/.ssh/${user}";
    };

    ssh_public_key = {
      sopsFile = ../../../secrets/ssh.yaml;
      key = "ssh_public_key";
      mode = "0644";
      owner = user;
      group = "users";
      path = "/home/${user}/.ssh/${user}.pub";
    };
  };

  system.activationScripts.sshConfig = ''
    mkdir -p /home/${user}/.ssh
    cat > /home/${user}/.ssh/config << 'EOF'
    # Default options for all hosts
    Host *
      AddKeysToAgent yes
      ControlMaster auto
      ControlPersist 10m

    # Ephemeral libvirt lab VMs (openstack-lab-*, 192.168.20x.0/24) — no PQ
    # KEX on stock RHEL-family OpenSSH, and not worth caring about for
    # throwaway internal VMs. See openssh.com/pq.html.
    Host 192.168.20?.*
      WarnWeakCrypto no

    # Internal hosts
    Host homeserver
      HostName homeserver.ts.${domain}
      User ${user}
      Port 2222
      IdentityFile ~/.ssh/${user}
      IdentitiesOnly yes

    Host desktop
      HostName desktop.ts.${domain}
      User ${user}
      IdentityFile ~/.ssh/${user}
      IdentitiesOnly yes

    Host desktop-wifi
      HostName ${config.my.network.hosts.desktop_wifi}
      User ${user}
      IdentityFile ~/.ssh/${user}
      IdentitiesOnly yes

    Host matebook
      HostName matebook.ts.${domain}
      User ${user}
      IdentityFile ~/.ssh/${user}
      IdentitiesOnly yes

    # External services
    Host gcp-relay
      HostName gcp-relay.ts.${domain}
      User ${user}
      IdentityFile ~/.ssh/${user}
      IdentitiesOnly yes

    Host github.com
      IdentityFile ~/.ssh/${user}
      IdentitiesOnly yes
    EOF
    chown ${user}:users /home/${user}/.ssh/config
    chmod 600 /home/${user}/.ssh/config
  '';

  networking.hosts =
    {
      "${config.my.network.gateway}" = ["router" "gateway" "router-mgmt"];

      "${config.my.network.hosts.homeserver_lan}" = ["homeserver" "serv"];
      "${config.my.network.hosts.desktop_lan}" = ["desktop" "desktop-lan"];
      "${config.my.network.hosts.desktop_wifi}" = ["desktop-wifi"];
      "${config.my.network.hosts.matebook_wifi}" = ["matebook"];

      "${config.my.network.infrastructure.switch-office}" = ["switch-office"];
      "${config.my.network.infrastructure.switch-living-room}" = ["switch-living-room"];
    }
    # Smart-home / entertainment / phone entries — generated from the private
    # DHCP reservation list (iot + media VLANs, plus any trusted-VLAN entry that
    # carries extra aliases).
    // lib.listToAttrs (map
      (r: lib.nameValuePair r.ip ([r.hostname] ++ (r.aliases or [])))
      (lib.filter (r: r.subnetId != 10 || (r.aliases or []) != []) config.my.network.reservations));

  programs.ssh.knownHosts = {
    "desktop" = {
      hostNames = ["desktop.ts.${domain}" config.my.network.hosts.desktop_ts];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH1T6RcXrs1aeupXBSVZlvYbispJAR+KROiJM6P+MUq2";
    };

    "homeserver" = {
      hostNames = ["homeserver.ts.${domain}" config.my.network.hosts.homeserver_ts];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJV+/pct8PNZhUqvnflYY5auIE1zTl3sPtCfVynTnajN";
    };

    "matebook" = {
      hostNames = ["matebook.ts.${domain}" config.my.network.hosts.matebook_ts];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILMexDvsxSWoErrJDM++L2N0dJxKc3ro7sIezfYIWFH2";
    };

    "gcp-relay" = {
      hostNames = [config.my.defaults.gcpRelayIp "gcp-relay" "gcp-relay.ts.${domain}" config.my.network.hosts."gcp-relay_ts"];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJM6PdGMBKVCzUboMTKIw6Dbdmy8HM8QVFibWy7PBVZZ";
    };

    "github.com-ecdsa-sha2-nistp256" = {
      hostNames = ["github.com"];
      publicKey = "AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg=";
    };

    "github.com-ed25519" = {
      hostNames = ["github.com"];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
    };

    "github.com-rsa" = {
      hostNames = ["github.com"];
      publicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCj7ndNxQowgcQnjshcLrqPEiiphnt+VTTvDP6mHBL9j1aNUkY4Ue1gvwnGLVlOhGeYrnZaMgRK6+PKCUXaDbC7qtbW8gIkhL7aGCsOr/C56SJMy/BCZfxd1nWzAOxSDPgVsmerOBYfNqltV9/hWCqBywINIR+5dIg6JTJ72pcEpEjcYgXkE2YEFXV1JHnsKgbLWNlhScqb2UmyRkQyytRLtL+38TGxkxCflmO+5Z8CSSNY7GidjMIZ7Q4zMjA2n1nGrlTDkzwDCsw+wqFPGQA179cnfGWOWRVruj16z6XyvxvjJwbz0wQZ75XK5tKSb7FNyeIEs4TT4jk+S4dhPeAUC5y+bDYirYgM4GC7uEnztnZyaVWQ7B381AK4Qdrwt51ZqExKbQpTUNn+EjqoTwvqNj4kqx5QUCI0ThS/YkOxJCXmPUWZbhjpCg56i+2aB6CmK2JGhn57K5mj0MNdBXA4/WnwH6XoPWJzK5Nyu2zB3nAZp+S5hpQs+p1vN1/wsjk=";
    };
  };
}
