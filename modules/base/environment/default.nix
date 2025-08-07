{ config, pkgs, ... }:
{
  environment = {
    # Secure system packages - minimal set only
    systemPackages = with pkgs; [
      # Essential system tools
      coreutils-full
      util-linux
      procps
      psmisc

      # Network tools
      iproute2
      iputils
      nettools

      # File management
      file
      tree
      rsync

      # Text processing
      gnugrep
      gnused
      gawk

      # System monitoring
      htop
      iotop
      lsof

      # Security tools
      openssh
      gnupg

      # Archive tools (minimal set)
      gzip
      bzip2
      xz

      # Remove development tools from system level:
      # gcc, python, nodejs, etc. should be in user profiles
    ];

    # Secure shell environment
    shellInit = ''
      # Security: set restrictive umask
      umask 027

      # Security: disable core dumps globally
      ulimit -c 0

      # Security: set secure PATH
      export PATH="/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin"

      # Security: clear potentially dangerous environment variables
      unset LD_PRELOAD
      unset LD_LIBRARY_PATH
      unset PYTHONPATH
      unset PERL5LIB
    '';

    # Secure variables
    variables = {
      EDITOR = "vim";
      VISUAL = "vim";
      PAGER = "less";
      LESS = "-R --quit-if-one-screen";

      # Security: restrict browser on server
      BROWSER = "lynx";

      # Security: set secure temp directories
      TMPDIR = "/tmp";
      TMP = "/tmp";
      TEMP = "/tmp";
    };

    # Session timeout for security
    interactiveShellInit = ''
      # Auto-logout after 30 minutes of inactivity
      export TMOUT=1800

      # Secure history settings
      export HISTCONTROL="ignoreboth:erasedups"
      export HISTSIZE=1000
      export HISTFILESIZE=2000
      export HISTTIMEFORMAT="%Y-%m-%d %H:%M:%S "

      # Security: clear sensitive variables on exit
      trap 'unset SSH_AUTH_SOCK SSH_AGENT_PID' EXIT
    '';

    # Remove desktop packages completely
    gnome.excludePackages = with pkgs; [
      # Remove all GNOME packages
    ];
  };

  # Secure /tmp
  boot.tmp = {
    useTmpfs = true;
    tmpfsSize = "25%"; # Limit tmp size
  };

  # Disable X11 and desktop services completely
  services.xserver.enable = false;
  xdg.portal.enable = false;
  programs.dconf.enable = false;
}
