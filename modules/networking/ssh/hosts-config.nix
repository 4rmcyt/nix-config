# Example SSH hosts configuration using the new options system
# This file shows how to migrate from the old ssh-hosts.nix to the new system
{config, ...}: let
  inherit (config.my.defaults) user;
in {
  my.ssh = {
    # Define SSH hosts
    hosts = {
      homeserver = {
        hostName = config.my.network.hosts.homeserver_lan;
        inherit user;
        identityFile = "~/.ssh/${user}";
        extraOptions = {
          IdentitiesOnly = "yes";
        };
        aliases = ["serv"];
      };

      desktop = {
        hostName = config.my.network.hosts.desktop_lan;
        inherit user;
        identityFile = "~/.ssh/${user}";
        extraOptions = {
          IdentitiesOnly = "yes";
        };
        aliases = ["desktop-lan"];
      };

      desktop-wifi = {
        hostName = config.my.network.hosts.desktop_wifi;
        inherit user;
        identityFile = "~/.ssh/${user}";
        extraOptions = {
          IdentitiesOnly = "yes";
        };
        aliases = [];
      };

      matebook = {
        hostName = config.my.network.hosts.matebook_wifi;
        inherit user;
        identityFile = "~/.ssh/${user}";
        extraOptions = {
          IdentitiesOnly = "yes";
        };
        aliases = [];
      };

      # External services
      "github.com" = {
        hostName = "github.com";
        user = "git";
        identityFile = "~/.ssh/${user}";
        extraOptions = {
          IdentitiesOnly = "yes";
        };
        aliases = [];
      };

      # Storage box (example with custom port)
      storagebox = {
        hostName = "u478963.your-storagebox.de";
        user = "u478963";
        port = 23;
        identityFile = "~/.ssh/storagebox"; # Can use separate key
        extraOptions = {
          IdentitiesOnly = "yes";
        };
        aliases = [];
      };
    };

    # Define known hosts
    knownHosts = {
      "github.com-ecdsa-sha2-nistp256" = {
        hostNames = ["github.com"];
        keyType = "ecdsa-sha2-nistp256";
        publicKey = "AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg=";
      };

      "github.com-ed25519" = {
        hostNames = ["github.com"];
        keyType = "ssh-ed25519";
        publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
      };

      "github.com-rsa" = {
        hostNames = ["github.com"];
        keyType = "ssh-rsa";
        publicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCj7ndNxQowgcQnjshcLrqPEiiphnt+VTTvDP6mHBL9j1aNUkY4Ue1gvwnGLVlOhGeYrnZaMgRK6+PKCUXaDbC7qtbW8gIkhL7aGCsOr/C56SJMy/BCZfxd1nWzAOxSDPgVsmerOBYfNqltV9/hWCqBywINIR+5dIg6JTJ72pcEpEjcYgXkE2YEFXV1JHnsKgbLWNlhScqb2UmyRkQyytRLtL+38TGxkxCflmO+5Z8CSSNY7GidjMIZ7Q4zMjA2n1nGrlTDkzwDCsw+wqFPGQA179cnfGWOWRVruj16z6XyvxvjJwbz0wQZ75XK5tKSb7FNyeIEs4TT4jk+S4dhPeAUC5y+bDYirYgM4GC7uEnztnZyaVWQ7B381AK4Qdrwt51ZqExKbQpTUNn+EjqoTwvqNj4kqx5QUCI0ThS/YkOxJCXmPUWZbhjpCg56i+2aB6CmK2JGhn57K5mj0MNdBXA4/WnwH6XoPWJzK5Nyu2zB3nAZp+S5hpQs+p1vN1/wsjk=";
      };

      "storagebox-ecdsa" = {
        hostNames = ["[u478963.your-storagebox.de]:23"];
        keyType = "ecdsa-sha2-nistp521";
        publicKey = "AAAAE2VjZHNhLXNoYTItbmlzdHA1MjEAAAAIbmlzdHA1MjEAAACFBAGK0po6usux4Qv2d8zKZN1dDvbWjxKkGsx7XwFdSUCnF19Q8psHEUWR7C/LtSQ5crU/g+tQVRBtSgoUcE8T+FWp5wBxKvWG2X9gD+s9/4zRmDeSJR77W6gSA/+hpOZoSE+4KgNdnbYSNtbZH/dN74EG7GLb/gcIpbUUzPNXpfKl7mQitw==";
      };

      "storagebox-ed25519" = {
        hostNames = ["[u478963.your-storagebox.de]:23"];
        keyType = "ssh-ed25519";
        publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIICf9svRenC/PLKIL9nk6K/pxQgoiFC41wTNvoIncOxs";
      };

      "storagebox-rsa" = {
        hostNames = ["[u478963.your-storagebox.de]:23"];
        keyType = "ssh-rsa";
        publicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA5EB5p/5Hp3hGW1oHok+PIOH9Pbn7cnUiGmUEBrCVjnAw+HrKyN8bYVV0dIGllswYXwkG/+bgiBlE6IVIBAq+JwVWu1Sss3KarHY3OvFJUXZoZyRRg/Gc/+LRCE7lyKpwWQ70dbelGRyyJFH36eNv6ySXoUYtGkwlU5IVaHPApOxe4LHPZa/qhSRbPo2hwoh0orCtgejRebNtW5nlx00DNFgsvn8Svz2cIYLxsPVzKgUxs8Zxsxgn+Q/UvR7uq4AbAhyBMLxv7DjJ1pc7PJocuTno2Rw9uMZi1gkjbnmiOh6TTXIEWbnroyIhwc8555uto5melEUmWNQ+C+PwAK+MPw==";
      };
    };

    # Override default options if needed
    defaultOptions = {
      AddKeysToAgent = "yes";
      ControlMaster = "auto";
      ControlPersist = "10m";
      # Add more defaults as needed
    };

    # Enable SOPS for SSH key management
    enableSecretsManagement = true;
  };
}
