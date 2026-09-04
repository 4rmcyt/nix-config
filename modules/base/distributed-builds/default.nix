{
  config,
  lib,
  ...
}: {
  options.my.distributedBuilds = {
    enable = lib.mkEnableOption "distributed builds configuration";

    role = lib.mkOption {
      type = lib.types.enum ["builder" "client" "both"];
      default = "both";
      description = "Role in distributed build setup";
    };

    builders = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          hostName = lib.mkOption {
            type = lib.types.str;
            description = "Hostname or IP of the build machine";
          };

          system = lib.mkOption {
            type = lib.types.str;
            default = "x86_64-linux";
            description = "System architecture the builder supports";
          };

          maxJobs = lib.mkOption {
            type = lib.types.int;
            default = 4;
            description = "Maximum number of concurrent jobs";
          };

          speedFactor = lib.mkOption {
            type = lib.types.int;
            default = 1;
            description = "Speed factor relative to localhost";
          };

          supportedFeatures = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = ["big-parallel"];
            description = "List of supported features";
          };

          publicHostKey = lib.mkOption {
            type = lib.types.str;
            description = "SSH public host key";
          };
        };
      });
      default = [];
      description = "List of remote builders";
    };
  };

  config = lib.mkIf config.my.distributedBuilds.enable {
    # Builder role: Accept build requests from other machines
    services.openssh = lib.mkIf (config.my.distributedBuilds.role == "builder" || config.my.distributedBuilds.role == "both") {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
      };
    };

    # Create nix-builder user on builder machines
    users.users.nix-builder = lib.mkIf (config.my.distributedBuilds.role == "builder" || config.my.distributedBuilds.role == "both") {
      isSystemUser = true;
      group = "nix-builder";
      openssh.authorizedKeys.keyFiles = [
        # SSH keys will be added here
      ];
    };

    users.groups.nix-builder = lib.mkIf (config.my.distributedBuilds.role == "builder" || config.my.distributedBuilds.role == "both") {};

    # Client role: Use remote builders
    nix = lib.mkIf (config.my.distributedBuilds.role == "client" || config.my.distributedBuilds.role == "both") {
      buildMachines =
        map (builder: {
          inherit (builder) hostName;
          systems = [builder.system];
          inherit (builder) maxJobs;
          inherit (builder) speedFactor;
          inherit (builder) supportedFeatures;
          mandatoryFeatures = [];
          sshUser = "nix-builder";
          sshKey = "/root/.ssh/nix-builder";
          inherit (builder) publicHostKey;
        })
        config.my.distributedBuilds.builders;

      distributedBuilds = lib.mkDefault true;

      settings = {
        builders-use-substitutes = lib.mkDefault true;
        # Require signature verification for packages from remote builders
        require-sigs = lib.mkDefault true;
      };

      extraOptions = ''
        builders-use-substitutes = true
      '';
    };

    # Add remote builders to known hosts
    programs.ssh.knownHosts =
      lib.mkIf (config.my.distributedBuilds.role == "client" || config.my.distributedBuilds.role == "both")
      (lib.listToAttrs (map (builder: {
          name = builder.hostName;
          value = {
            publicKey = builder.publicHostKey;
          };
        })
        config.my.distributedBuilds.builders));
  };
}
