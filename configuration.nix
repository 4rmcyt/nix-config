{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./modules/users
    ./modules/networking
    ./modules/services
    ./modules/base
  ];

  sops.secrets = {
    ssh_host_ed25519_key = { sopsFile = ../../secrets/system.yaml; key = "ssh_host_ed25519_key"; owner = config.users.users.root.name;  group = config.users.groups.root.name; mode = "0600"; };
    ssh_host_rsa_key = { sopsFile = ../../secrets/system.yaml; key = "ssh_host_rsa_key"; owner = config.users.users.root.name; group = config.users.groups.root.name; mode = "0600"; };
    borg_private_key = { sopsFile = ../../secrets/system.yaml; key = "borg_private_key"; owner = config.users.users.root.name; group = config.users.groups.root.name; };
  };

  environment.systemPackages = with pkgs; [
    zsh
    git
    neovim
    direnv
    pass
    vim
    wget
    curl
    jq
    coreutils
    gawk
    gnugrep
    iproute2
    mc
    htop
    btop
    lsof
    age
    sops
    ssh-to-age
    openssh
    wireguard-tools
    dive
    apacheHttpd
    meslo-lgs-nf
    yamllint
    nix-index
    iotop
    cachix
    tuptime
    smartmontools
    fzf
    ffmpeg
    nmap
    trash-cli
    zip
    unar
    unzip
    p7zip
    go
    nextdns
    nixfmt-rfc-style
    nil
    deploy-rs
    just
    nixpkgs-fmt
    tree
    git-crypt
    python3Full
    borgbackup
    smartmontools
    openssl
    fwupd
  ];
  
  services = {
    openssh = {
      enable = true;
      hostKeys = [
        {
          type = "ed25519";
          path = config.sops.secrets.ssh_host_ed25519_key.path;
        }
        {
          type = "rsa";
          bits = 4096;
          path = config.sops.secrets.ssh_host_rsa_key.path;
        }
        {
          type = "ed25519";
          path = config.sops.secrets.borg_private_key.path;
        }
      ];
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = true;
      };
      extraConfig = ''
        Match user git
          AllowTcpForwarding no
          AllowAgentForwarding no
          PasswordAuthentication no
          PermitTTY no
          X11Forwarding no
      '';
      knownHosts = {
        "github.com-ed25519".publicKey =
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
        "github.com-rsa".publicKey =
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCj7ndNxQowgcQnjshcLrqPEiiphnt+VTTvDP6mHBL9j1aNUkY4Ue1gvwnGLVlOhGeYrnZaMgRK6+PKCUXaDbC7qtbW8gIkhL7aGCsOr/C56SJMy/BCZfxd1nWzAOxSDPgVsmerOBYfNqltV9/hWCqBywINIR+5dIg6JTJ72pcEpEjcYgXkE2YEFXV1JHnsKgbLWNlhScqb2UmyRkQyytRLtL+38TGxkxCflmO+5Z8CSSNY7GidjMIZ7Q4zMjA2n1nGrlTDkzwDCsw+wqFPGQA179cnfGWOWRVruj16z6XyvxvjJwbz0wQZ75XK5tKSb7FNyeIEs4TT4jk+S4dhPeAUC5y+bDYirYgM4GC7uEnztnZyaVWQ7B381AK4Qdrwt51ZqExKbQpTUNn+EjqoTwvqNj4kqx5QUCI0ThS/YkOxJCXmPUWZbhjpCg56i+2aB6CmK2JGhn57K5mj0MNdBXA4/WnwH6XoPWJzK5Nyu2zB3nAZp+S5hpQs+p1vN1/wsjk=";
        "github.com-ecdsa-sha2-nistp256".publicKey =
          "AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg=";
        "[u478963.your-storagebox.de]:23-ssh-ed25519".publicKey =
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIICf9svRenC/PLKIL9nk6K/pxQgoiFC41wTNvoIncOxs";
        "[u478963.your-storagebox.de]:23-ssh-rsa".publicKey =
          " ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA5EB5p/5Hp3hGW1oHok+PIOH9Pbn7cnUiGmUEBrCVjnAw+HrKyN8bYVV0dIGllswYXwkG/+bgiBlE6IVIBAq+JwVWu1Sss3KarHY3OvFJUXZoZyRRg/Gc/+LRCE7lyKpwWQ70dbelGRyyJFH36eNv6ySXoUYtGkwlU5IVaHPApOxe4LHPZa/qhSRbPo2hwoh0orCtgejRebNtW5nlx00DNFgsvn8Svz2cIYLxsPVzKgUxs8Zxsxgn+Q/UvR7uq4AbAhyBMLxv7DjJ1pc7PJocuTno2Rw9uMZi1gkjbnmiOh6TTXIEWbnroyIhwc8555uto9melEUmWNQ+C+PwAK+MPw==";
        "[u478963.your-storagebox.de]:23-ecdsa-sha2-nistp521".publicKey =
          "AAAAE2VjZHNhLXNoYTItbmlzdHA1MjEAAAAIbmlzdHA1MjEAAACFBAGK0po6usux4Qv2d8zKZN1dDvbWjxKkGsx7XwFdSUCnF19Q8psHEUWR7C/LtSQ5crU/g+tQVRBtSgoUcE8T+FWp5wBxKvWG2X9gD+s9/4zRmDeSJR77W6gSA/+hpOZoSE+4KgNdnbYSNtbZH/dN74EG7GLb/gcIpbUUzPNXpfKl7mQitw==";
      };
    };

    ollama = {
      enable = false;
      loadModels = [
        "phi3:mini" # Specify the model you want to pre-load
      ];
    };

    
    vscode-server.enable = true;
  };
  system.stateVersion = "25.05";
}
