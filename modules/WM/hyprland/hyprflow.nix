# Save/restore Hyprland window sessions. Not packaged in nixpkgs — built
# from source. See https://github.com/isorensen/hyprflow
{
  lib,
  pkgs,
  ...
}: let
  hyprflow = pkgs.rustPlatform.buildRustPackage rec {
    pname = "hyprflow";
    version = "0.2.1";

    src = pkgs.fetchFromGitHub {
      owner = "isorensen";
      repo = "hyprflow";
      rev = "v${version}";
      hash = lib.fakeHash;
    };

    cargoLock.lockFile = "${src}/Cargo.lock";

    meta = {
      description = "Save and restore Hyprland window sessions";
      homepage = "https://github.com/isorensen/hyprflow";
      license = lib.licenses.mit;
      mainProgram = "hyprflow";
    };
  };
in {
  home.packages = [hyprflow];

  xdg.configFile."hyprflow/config.toml".text = ''
    [general]
    default_session = "latest"
    restore_delay_ms = 500
    window_detect_timeout_ms = 5000
    autosave_retain = 5
  '';

  # Mirrors what `hyprflow autosave --install` would generate (src/autosave.rs
  # upstream), but declared here so it's reproducible across rebuilds instead
  # of a one-off imperative install step.
  systemd.user.services.hyprflow-autosave = {
    Unit.Description = "Hyprflow autosave session";
    Service = {
      Type = "oneshot";
      ExecStart = "${lib.getExe hyprflow} autosave --now";
    };
  };

  systemd.user.timers.hyprflow-autosave = {
    Unit.Description = "Hyprflow autosave timer";
    Timer = {
      OnUnitActiveSec = "10min";
      OnBootSec = "1min";
    };
    Install.WantedBy = ["timers.target"];
  };
}
