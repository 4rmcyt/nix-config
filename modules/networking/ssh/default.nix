{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.my.ssh;
  inherit (config.my.defaults) user;

  # Generate SSH config entries
  generateSSHConfig = hosts:
    concatStringsSep "\n\n" (mapAttrsToList (name: hostCfg: ''
        Host ${name}
          HostName ${hostCfg.hostName}
          User ${hostCfg.user}
          ${optionalString (hostCfg.port != 22) "Port ${toString hostCfg.port}"}
          IdentityFile ${hostCfg.identityFile}
          ${concatStringsSep "\n  " (mapAttrsToList (k: v: "${k} ${v}") hostCfg.extraOptions)}
      '')
      hosts);

  # Generate /etc/hosts entries
  generateHostsEntries = hosts:
    listToAttrs (
      flatten (mapAttrsToList (name: hostCfg:
        optional (hostCfg.aliases != []) {
          name = hostCfg.hostName;
          value = [name] ++ hostCfg.aliases;
        })
      hosts)
    );
in {
  config = mkIf (cfg.hosts != {}) {
    # SOPS secrets for SSH keys
    sops.secrets = mkIf cfg.enableSecretsManagement {
      ssh_private_key = {
        sopsFile = ../../../secrets/ssh/${user}_ed25519;
        format = "binary";
        mode = "0600";
        owner = user;
        group = "users";
        path = "/home/${user}/.ssh/${user}";
      };

      ssh_public_key = {
        sopsFile = ../../../secrets/ssh/${user}_ed25519.pub;
        format = "binary";
        mode = "0644";
        owner = user;
        group = "users";
        path = "/home/${user}/.ssh/${user}.pub";
      };

      # Optional: Additional keys for specific services
      # ssh_storagebox_key = {
      #   sopsFile = ../../../secrets/ssh/storagebox_ed25519;
      #   format = "binary";
      #   mode = "0600";
      #   owner = user;
      #   group = "users";
      #   path = "/home/${user}/.ssh/storagebox";
      # };
    };

    # SSH client configuration
    system.activationScripts.sshConfig = ''
      mkdir -p /home/${user}/.ssh
      cat > /home/${user}/.ssh/config << 'EOF'
      # Default options for all hosts
      Host *
        ${concatStringsSep "\n  " (mapAttrsToList (k: v: "${k} ${v}") cfg.defaultOptions)}

      ${generateSSHConfig cfg.hosts}
      EOF
      chown ${user}:users /home/${user}/.ssh/config
      chmod 600 /home/${user}/.ssh/config
    '';

    # /etc/hosts entries
    networking.hosts = mkMerge [
      (generateHostsEntries cfg.hosts)
      # Keep existing network infrastructure hosts from network options
      {
        "${config.my.network.gateway}" = ["router" "gateway" "router-mgmt"];
        "${config.my.network.infrastructure.switch-office}" = ["switch-office"];
        "${config.my.network.infrastructure.switch-living-room}" = ["switch-living-room"];
      }
    ];

    # SSH known hosts
    programs.ssh.knownHosts =
      mapAttrs (_name: hostCfg: {
        inherit (hostCfg) hostNames publicKey;
      })
      cfg.knownHosts;
  };
}
