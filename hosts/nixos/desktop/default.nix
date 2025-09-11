{
  pkgs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ../../../modules/gaming
    ../../../modules/users/zeev
    ../../../modules/disko/desktop
    ../../../modules/base
  ];

  # Add the missing git group
  users.groups.git = { };
  users.users.git = {
    isSystemUser = true;
    group = "git";
    home = "/var/lib/git";
    createHome = true;
    shell = pkgs.bash;
  };

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.permittedInsecurePackages = [
    "qtwebengine-5.15.19" # Replace with the specific version
  ];

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  services.scx.enable = true;

  # Enable X11 and KDE Plasma
  services.xserver = {
    enable = true;
    videoDrivers = [ "nvidia" ];
    
    # Display manager and desktop environment
    displayManager.sddm.enable = true;
    desktopManager.plasma5.enable = true;
    
    # Configure keyboard
    xkb = {
      layout = "us";
      variant = "";
    };
  };

  # KDE Plasma 6 (latest) - comment out plasma5 above and uncomment below if you want Plasma 6
  # services.desktopManager.plasma6.enable = true;

  # Networking with WiFi support
  networking = {
    hostName = "desktop";
    hostId = "e134040f";
    networkmanager.enable = true;
    wireless.enable = false;
    firewall.enable = true;
  };

  # Tailscale
  services.tailscale.enable = true;

  # Time zone and locale
  time.timeZone = "America/Edmonton";
  i18n.defaultLocale = "en_US.UTF-8";

  # Audio - PipeWire with KDE integration
  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    lowLatency = {
      enable = true;
      quantum = 64;
      rate = 48000;
    };
  };

  security.rtkit.enable = true;
  services.openssh.enable = true;

  # Enable printing support
  services.printing.enable = true;

  # Enable bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  environment.systemPackages = with pkgs; [
    # Basic tools
    vim
    wget
    curl
    git
    htop
    neofetch
    nvtopPackages.nvidia
    tailscale
    helix_git
    direnv
    btop
    nixfmt

    # KDE Applications and tools
    kdePackages.kate
    kdePackages.konsole
    kdePackages.dolphin
    kdePackages.ark
    kdePackages.okular
    kdePackages.gwenview
    kdePackages.spectacle
    kdePackages.krunner
    kdePackages.systemsettings
    kdePackages.plasma-workspace
    kdePackages.plasma-desktop
    kdePackages.kwin
    kdePackages.breeze
    kdePackages.breeze-gtk
    kdePackages.oxygen
    kdePackages.kinfocenter
    kdePackages.plasma-pa
    kdePackages.plasma-nm
    kdePackages.bluedevil
    kdePackages.powerdevil
    kdePackages.kscreen
    kdePackages.plasma-workspace-wallpapers

    # Additional KDE utilities
    kdePackages.kcalc
    kdePackages.kcharselect
    kdePackages.kcolorchooser
    kdePackages.kruler
    kdePackages.kfind
    kdePackages.filelight
    
    # GUI Applications
    firefox
    discord
    telegram-desktop_git
    jellyfin-media-player
    vscode
    steam
    lutris

    # Multimedia
    vlc
    gimp
    inkscape

    # System utilities
    gparted
    firefox
    chromium
    thunderbird
    libreoffice-qt6-fresh
  ];

  # Fonts
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    font-awesome
    nerd-fonts.fira-code
    dejavu_fonts
    ubuntu_font_family
  ];

  # Enable some additional services for better KDE experience
  services.udev.packages = with pkgs; [ gnome.gnome-settings-daemon ];
  
  # Configure Qt and GTK themes
  qt = {
    enable = true;
    platformTheme = "kde";
    style = "breeze";
  };

  # Nix settings
  nix = {
    package = pkgs.nixVersions.latest;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      fallback = true;
      system-features = [
        "big-parallel"
        "kvm"
      ];
      trusted-users = [ "zeev" ];
      warn-dirty = false;
      cores = 6;
      max-jobs = 6;
      show-trace = true;
      download-buffer-size = 1073741824;
    };
    optimise = {
      automatic = true;
      dates = [ "weekly" ];
    };
  };

  # NVIDIA configuration
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
    package = pkgs.linuxPackages.nvidiaPackages.stable;
  };

  # Enable home-manager backup for conflicting files
  home-manager.backupFileExtension = "backup";

  system.stateVersion = "25.05";
}