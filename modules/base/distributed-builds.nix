{
  config,
  lib,
  ...
}: {
  options.distributed-builds = {
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
            default = ["nixos-test" "benchmark" "big-parallel" "kvm"];
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

  config = lib.mkIf config.distributed-builds.enable {
    # Builder role: Accept build requests from other machines
    services.openssh = lib.mkIf (config.distributed-builds.role == "builder" || config.distributed-builds.role == "both") {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
      };
    };

    # Create nix-builder user on builder machines
    users.users.nix-builder = lib.mkIf (config.distributed-builds.role == "builder" || config.distributed-builds.role == "both") {
      isSystemUser = true;
      group = "nix-builder";
      openssh.authorizedKeys.keyFiles = [
        # SSH keys will be added here
      ];
    };

    users.groups.nix-builder = lib.mkIf (config.distributed-builds.role == "builder" || config.distributed-builds.role == "both") {};

    # Client role: Use remote builders
    nix = lib.mkIf (config.distributed-builds.role == "client" || config.distributed-builds.role == "both") {
      buildMachines =
        map (builder: {
          inherit (builder) hostName;
          inherit (builder) system;
          inherit (builder) maxJobs;
          inherit (builder) speedFactor;
          inherit (builder) supportedFeatures;
          mandatoryFeatures = [];
          sshUser = "nix-builder";
          sshKey = "/root/.ssh/nix-builder";
          inherit (builder) publicHostKey;
        })
        config.distributed-builds.builders;

      distributedBuilds = lib.mkDefault true;

      settings = {
        builders-use-substitutes = lib.mkDefault true;
        # Fallback to local builds if remote builders are unavailable
        require-sigs = lib.mkDefault false; # Allow unsigned paths from builders
      };

      extraOptions = ''
        builders-use-substitutes = true
      '';
    };

    # Add remote builders to known hosts
    programs.ssh.knownHosts =
      lib.mkIf (config.distributed-builds.role == "client" || config.distributed-builds.role == "both")
      (lib.listToAttrs (map (builder: {
          name = builder.hostName;
          value = {
            publicKey = builder.publicHostKey;
          };
        })
        config.distributed-builds.builders));
  };
}
