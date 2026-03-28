{config, ...}: let
  inherit (config.my.defaults) user;
in {
  # =================================================================
  # SSH Secrets Management with SOPS
  # =================================================================
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

  # =================================================================
  # SSH Client Configuration
  # =================================================================
  system.activationScripts.sshConfig = ''
    mkdir -p /home/${user}/.ssh
    cat > /home/${user}/.ssh/config << 'EOF'
    # Default options for all hosts
    Host *
      AddKeysToAgent yes
      ControlMaster auto
      ControlPersist 10m

    # Internal hosts
    Host homeserver
      HostName ${config.my.network.hosts.homeserver_lan}
      User ${user}
      Port 2222
      IdentityFile ~/.ssh/${user}
      IdentitiesOnly yes

    Host desktop
      HostName ${config.my.network.hosts.desktop_lan}
      User ${user}
      IdentityFile ~/.ssh/${user}
      IdentitiesOnly yes

    Host desktop-wifi
      HostName ${config.my.network.hosts.desktop_wifi}
      User ${user}
      IdentityFile ~/.ssh/${user}
      IdentitiesOnly yes

    Host matebook
      HostName ${config.my.network.hosts.matebook_wifi}
      User ${user}
      IdentityFile ~/.ssh/${user}
      IdentitiesOnly yes

    # External services
    Host github.com
      IdentityFile ~/.ssh/${user}
      IdentitiesOnly yes
    EOF
    chown ${user}:users /home/${user}/.ssh/config
    chmod 600 /home/${user}/.ssh/config
  '';

  # =================================================================
  # /etc/hosts Configuration
  # =================================================================
  networking.hosts = {
    # Gateway / Router
    "${config.my.network.gateway}" = ["router" "gateway" "router-mgmt"];

    # Primary systems
    "${config.my.network.hosts.homeserver_lan}" = ["homeserver" "serv"];
    "${config.my.network.hosts.desktop_lan}" = ["desktop" "desktop-lan"];
    "${config.my.network.hosts.desktop_wifi}" = ["desktop-wifi"];
    "${config.my.network.hosts.matebook_wifi}" = ["matebook"];

    # Network infrastructure
    "${config.my.network.infrastructure.switch-office}" = ["switch-office"];
    "${config.my.network.infrastructure.switch-living-room}" = ["switch-living-room"];

    # Smart home devices
    "${config.my.network.smart-home.plugs.office}" = ["plug-office"];
    "${config.my.network.smart-home.plugs.entrance}" = ["plug-entrance"];
    "${config.my.network.smart-home.plugs.table}" = ["plug-table"];
    "${config.my.network.smart-home.plugs.window}" = ["plug-window"];
    "${config.my.network.smart-home.plugs.salt}" = ["plug-salt"];
    "${config.my.network.smart-home.humidifier}" = ["humidifier"];
    "${config.my.network.smart-home.alexa-echo-show}" = ["alexa" "echo-show"];

    # Entertainment devices
    "${config.my.network.entertainment.roku-tv}" = ["roku-tv" "tv"];
    "${config.my.network.entertainment.mi-box-s}" = ["mi-box" "android-tv"];
    "${config.my.network.entertainment.playstation-5}" = ["ps5" "playstation"];
    "${config.my.network.entertainment.nintendo-switch}" = ["switch" "nintendo"];

    # Mobile devices
    "${config.my.network.mobile.sophia-s23-ultra}" = ["sophia-phone"];
    "${config.my.network.mobile.volodymyr-s23}" = ["volodymyr-phone" "s23plus"];
  };

  # =================================================================
  # SSH Known Hosts
  # =================================================================
  programs.ssh.knownHosts = {
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

    "[u478963.your-storagebox.de]:23-ecdsa-sha2-nistp521" = {
      hostNames = ["[u478963.your-storagebox.de]:23"];
      publicKey = "AAAAE2VjZHNhLXNoYTItbmlzdHA1MjEAAAAIbmlzdHA1MjEAAACFBAGK0po6usux4Qv2d8zKZN1dDvbWjxKkGsx7XwFdSUCnF19Q8psHEUWR7C/LtSQ5crU/g+tQVRBtSgoUcE8T+FWp5wBxKvWG2X9gD+s9/4zRmDeSJR77W6gSA/+hpOZoSE+4KgNdnbYSNtbZH/dN74EG7GLb/gcIpbUUzPNXpfKl7mQitw==";
    };

    "[u478963.your-storagebox.de]:23-ssh-ed25519" = {
      hostNames = ["[u478963.your-storagebox.de]:23"];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIICf9svRenC/PLKIL9nk6K/pxQgoiFC41wTNvoIncOxs";
    };

    "[u478963.your-storagebox.de]:23-ssh-rsa" = {
      hostNames = ["[u478963.your-storagebox.de]:23"];
      publicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA5EB5p/5Hp3hGW1oHok+PIOH9Pbn7cnUiGmUEBrCVjnAw+HrKyN8bYVV0dIGllswYXwkG/+bgiBlE6IVIBAq+JwVWu1Sss3KarHY3OvFJUXZoZyRRg/Gc/+LRCE7lyKpwWQ70dbelGRyyJFH36eNv6ySXoUYtGkwlU5IVaHPApOxe4LHPZa/qhSRbPo2hwoh0orCtgejRebNtW5nlx00DNFgsvn8Svz2cIYLxsPVzKgUxs8Zxsxgn+Q/UvR7uq4AbAhyBMLxv7DjJ1pc7PJocuTno2Rw9uMZi1gkjbnmiOh6TTXIEWbnroyIhwc8555uto5melEUmWNQ+C+PwAK+MPw==";
    };
  };
}
