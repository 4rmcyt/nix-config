{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.my.kernel;
in {
  imports = [
    ./modprobed-db.nix
  ];

  options.my.kernel = {
    optimized = {
      enable = mkEnableOption "kernel optimization using modprobed-db";

      modulesPath = mkOption {
        type = types.path;
        default = /var/lib/modprobed-db/.config/modprobed-db/modprobed.db;
        description = "Path to modprobed.db file containing kernel modules";
      };

      compiler = mkOption {
        type = types.enum ["gcc" "clang"];
        default = "gcc";
        description = "Compiler to use for kernel build";
      };

      march = mkOption {
        type = types.str;
        default = "native";
        description = "CPU architecture to optimize for (native, znver4, etc)";
      };
    };
  };

  config = mkMerge [
    # Base modprobed-db service configuration
    {
      services.modprobed-db = {
        enable = true;
        user = "root";
        interval = "hourly";
      };
    }

    # Kernel optimization configuration
    (mkIf cfg.optimized.enable {
      boot.kernelPackages = let
        # Read the modprobed.db file if it exists
        modulesFile = cfg.optimized.modulesPath;

        # Custom kernel configuration
        customKernel = pkgs.linuxPackages_cachyos.kernel.override {
          structuredExtraConfig = with lib.kernel; {
            # Enable module loading
            MODULES = yes;
            MODULE_UNLOAD = yes;

            # Optimize for specific CPU
            GENERIC_CPU = no;
            MNATIVE_AMD = mkIf (cfg.optimized.march == "native") yes;

            # Performance optimizations
            PREEMPT_VOLUNTARY = yes;
            HZ_1000 = yes;
            HZ = freeform "1000";

            # Disable unnecessary features
            DEBUG_KERNEL = no;
            DEBUG_INFO = no;

            # Enable only needed modules (set to module instead of yes)
            # This allows us to build only what's needed
            MODULE_SIG = no;
          };

          # Use the specified compiler
          stdenv = if cfg.optimized.compiler == "clang"
                   then pkgs.llvmPackages_latest.stdenv
                   else pkgs.stdenv;
        };
      in
        pkgs.linuxPackages_cachyos.extend (self: super: {
          kernel = customKernel;
        });

      # Inform user about kernel optimization
      warnings = mkIf (!builtins.pathExists cfg.optimized.modulesPath) [
        ''
          Kernel optimization is enabled but modprobed.db not found at ${toString cfg.optimized.modulesPath}.
          Run modprobed-db for a few days/weeks to collect module data before rebuilding kernel.
          The systemd service will automatically track modules.
        ''
      ];
    })
  ];
}
