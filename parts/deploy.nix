{
  config,
  inputs,
  ...
}: let
  inherit (config.meta) owner;
  deployLib = inputs.deploy-rs.lib.x86_64-linux;

  mkNode = hostname: targetHost: extraArgs: {
    inherit hostname;
    sshUser = owner.username;
    profiles.system = {
      user = "root";
      path = deployLib.activate.nixos config.flake.nixosConfigurations.${hostname};
    } // extraArgs;
  };
in {
  flake.deploy.nodes = {
    homeserver = mkNode "homeserver" owner.homeserverLan {
      magicRollback = true;
      autoRollback = true;
    };

    desktop = mkNode "desktop" owner.desktopLan {
      magicRollback = false; # local machine, no risk
      autoRollback = false;
    };

    matebook = mkNode "matebook" owner.matebookWifi {
      magicRollback = true;
      autoRollback = true;
    };

    gcp-relay = mkNode "gcp-relay" "gcp-relay" {
      magicRollback = true;
      autoRollback = true;
      sshOpts = ["-p" "22"];
    };
  };

}