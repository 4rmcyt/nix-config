{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    tmux
    tmuxPlugins
  ];
  programs.tmux = {
    enable = true;
    shell = "${pkgs.bash}/bin/zsh";
    shortcut = "a";
    aggressiveResize = true;
    baseIndex = 1;
    newSession = true;
    # Stop tmux+escape craziness.
    escapeTime = 0;
    # Force tmux to use /tmp for sockets (WSL2 compat)
    secureSocket = false;
    mouse = true;
    clock24 = true;
    historyLimit = 500000;

    plugins = with pkgs; [
      tmuxPlugins.better-mouse-mode
      tmuxPlugins.tmux-cowboy
      tmuxPlugins.tmux-menus
      tmuxPlugins.tmux-continuum
      tmuxPlugins.tmux-fzf
      tmuxPlugins.tmux-resurrect
      tmuxPlugins.tmux-named-snapshot
      tmuxPlugins.tmux-mem-cpu-load
      tmuxPlugins.tmux-prefix-highlight
      tmuxPlugins.tmux-logging
      tmuxPlugins.extrakto
      tmuxPlugins.muxile
    ];

    extraConfig = ''
      # https://old.reddit.com/r/tmux/comments/mesrci/tmux_2_doesnt_seem_to_use_256_colors/
      set -g default-terminal "xterm-256color"
      set -ga terminal-overrides ",*256col*:Tc"
      set -ga terminal-overrides '*:Ss=\E[%p1%d q:Se=\E[ q'
      set-environment -g COLORTERM "truecolor"
      set -g status-right '#[fg=green]#($TMUX_PLUGIN_MANAGER_PATH/tmux-mem-cpu-load/tmux-mem-cpu-load --colors --powerline-right --interval 2)#[default]'
      set -ga update-environment EDITOR
      set -g @super-fingers-key f


      # easy-to-remember split pane commands
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
      bind c new-window -c "#{pane_current_path}"
    '';
  };

  # programs.tmate = {
  #   enable = true;
  #   # FIXME: This causes tmate to hang.
  #   # extraConfig = config.xdg.configFile."tmux/tmux.conf".text;
  # };
}
