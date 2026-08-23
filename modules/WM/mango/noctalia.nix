{pkgs, ...}: {
  programs.noctalia-shell = {
    enable = true;
    # exec-once configured in startup.nix; systemd service not used

    settings = {};
  };

  # noctalia-shell's own package wraps `qs` with
  # `--set-default QS_CONFIG_PATH "$out/share/noctalia-shell"` — an
  # ephemeral /nix/store path that changes every generation. Quickshell's
  # IPC instance discovery keys off that path, so `noctalia-shell ipc call`
  # run from a shell whose PATH resolved a *different* generation's wrapper
  # than the one mango's autostart actually launched reports "No running
  # instances" even though the shell is alive and responsive to input.
  # Named configs sidestep this: quickshell resolves `-c noctalia-shell` to
  # this stable `~/.config/quickshell/noctalia-shell` symlink regardless of
  # which generation is current, so launch and ipc-call always agree on
  # identity. See https://github.com/noctalia-dev/noctalia/issues/2016.
  xdg.configFile."quickshell/noctalia-shell".source = "${pkgs.noctalia-shell}/share/noctalia-shell";

  # playerctl for media key bindings, quickshell for the -c noctalia-shell
  # invocation above (programs.noctalia-shell only installs the
  # noctalia-shell wrapper binary, not the bare quickshell/qs binary)
  home.packages = [pkgs.playerctl pkgs.quickshell];
}
