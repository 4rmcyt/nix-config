{ config, ... }:
{
  sops.age.keyFile = "/var/lib/sops/age.key";
  sops.defaultSopsFormat = "yaml";

  sops.secrets = {
    ssh_host_ed25519_key = { 
      sopsFile = ../../../secrets/system.yaml; 
      key = "ssh_host_ed25519_key"; 
      owner = config.users.users.sshd.name; 
      group = config.users.users.sshd.group;
      mode = "0600";
    };
    ssh_host_rsa_key = { 
      sopsFile = ../../../secrets/system.yaml; 
      key = "ssh_host_rsa_key"; 
      owner = config.users.users.sshd.name;
      group = config.users.users.sshd.group;
      mode = "0600"; 
    };
  };
}
