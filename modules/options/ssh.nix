{lib, ...}:
with lib; {
  options.my.ssh = {
    hosts = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          hostName = mkOption {
            type = types.str;
            description = "Hostname or IP address";
          };
          user = mkOption {
            type = types.str;
            description = "SSH user";
          };
          port = mkOption {
            type = types.int;
            default = 22;
            description = "SSH port";
          };
          identityFile = mkOption {
            type = types.str;
            description = "Path to SSH identity file";
          };
          extraOptions = mkOption {
            type = types.attrsOf types.str;
            default = {};
            description = "Additional SSH options";
            example = {
              IdentitiesOnly = "yes";
              ForwardAgent = "yes";
            };
          };
          aliases = mkOption {
            type = types.listOf types.str;
            default = [];
            description = "Alternative hostnames for /etc/hosts";
          };
        };
      });
      default = {};
      description = "SSH host configurations";
    };

    knownHosts = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          hostNames = mkOption {
            type = types.listOf types.str;
            description = "List of hostnames";
          };
          publicKey = mkOption {
            type = types.str;
            description = "Public key for the host";
          };
          keyType = mkOption {
            type = types.enum ["ssh-rsa" "ssh-ed25519" "ecdsa-sha2-nistp256" "ecdsa-sha2-nistp384" "ecdsa-sha2-nistp521"];
            default = "ssh-ed25519";
            description = "SSH key type";
          };
        };
      });
      default = {};
      description = "SSH known hosts configuration";
    };

    defaultOptions = mkOption {
      type = types.attrsOf types.str;
      default = {
        AddKeysToAgent = "yes";
        ControlMaster = "auto";
        ControlPersist = "10m";
      };
      description = "Default SSH client options for all hosts";
    };

    enableSecretsManagement = mkOption {
      type = types.bool;
      default = true;
      description = "Enable SOPS-based SSH key management";
    };
  };
}
