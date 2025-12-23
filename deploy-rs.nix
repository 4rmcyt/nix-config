{
  inputs,
  system,
}: {
  nodes = {
    homeserver = {
      hostname = "homeserver"; # Change to actual hostname/IP
      profiles.system = {
        sshUser = "root";
        user = "root";
        path = inputs.deploy-rs.lib.${system}.activate.nixos inputs.self.nixosConfigurations.homeserver;
      };
    };

    matebook = {
      hostname = "matebook"; # Change to actual hostname/IP
      profiles.system = {
        sshUser = "root";
        user = "root";
        path = inputs.deploy-rs.lib.${system}.activate.nixos inputs.self.nixosConfigurations.matebook;
      };
    };

    desktop = {
      hostname = "desktop"; # Change to actual hostname/IP
      profiles.system = {
        sshUser = "root";
        user = "root";
        path = inputs.deploy-rs.lib.${system}.activate.nixos inputs.self.nixosConfigurations.desktop;
      };
    };
  };
}
