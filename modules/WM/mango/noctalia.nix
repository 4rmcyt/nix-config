{pkgs, ...}: let
  # noctalia-shell (legacy-v4, archived upstream) drives mango over its
  # `mmsg` CLI using flags from an older mango release: `mmsg -s -d <func>`,
  # `mmsg -s -q`. Current mango-nightly's mmsg only understands the newer
  # `mmsg dispatch <func>` form — `-s -d` fails with {"error":"unknown
  # command"}, silently, since Services/Compositor/MangoService.qml only
  # catches JS exceptions from execDetached(), not the child's exit status.
  # This is why every launcher click (spawn), window close, monitor
  # power-toggle, and logout via MangoService silently did nothing. Since
  # v4 gets no more upstream fixes, patch the two-line CLI-args shape here.
  # NOT touched: the `mmsg -g -A` scale query — its response is parsed with
  # a line-based regex tied to that flag's specific text output, so
  # switching it to `dispatch`/`get` without also updating the parser would
  # trade a silent launcher failure for silent monitor-scale detection
  # failure. And the switchToWorkspace `-s -t` fallback is effectively dead
  # code: DwlIpc.setTags() (the primary path) is always available here.
  patchedNoctaliaShell = pkgs.runCommand "noctalia-shell-mango-mmsg-fixed" {} ''
    mkdir -p "$out"
    cp -r ${pkgs.noctalia-shell}/share/noctalia-shell/. "$out"/
    chmod -R u+w "$out"
    substituteInPlace "$out/Services/Compositor/MangoService.qml" \
      --replace-fail '"mmsg", "-s", "-d", "spawn_shell," + command.join(" ")' \
                      '"mmsg", "dispatch", "spawn_shell," + command.join(" ")' \
      --replace-fail '["mmsg", "-s", "-d", "killclient"]' \
                      '["mmsg", "dispatch", "killclient"]' \
      --replace-fail '"mmsg -s -d disable_monitor," + screens[i].name' \
                      '"mmsg dispatch disable_monitor," + screens[i].name' \
      --replace-fail '"mmsg -s -d enable_monitor," + screens[i].name' \
                      '"mmsg dispatch enable_monitor," + screens[i].name' \
      --replace-fail '["mmsg", "-s", "-q"]' \
                      '["mmsg", "dispatch", "quit"]'
  '';
in {
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
  xdg.configFile."quickshell/noctalia-shell".source = patchedNoctaliaShell;

  # playerctl for media key bindings, quickshell for the -c noctalia-shell
  # invocation above (programs.noctalia-shell only installs the
  # noctalia-shell wrapper binary, not the bare quickshell/qs binary)
  home.packages = [pkgs.playerctl pkgs.quickshell];
}
