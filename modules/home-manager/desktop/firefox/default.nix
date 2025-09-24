{
  features.browser = "firefox"; # Change if we ever stop using Firefox (unlikely)

  hm.programs.firefox = {
    enable = true;

    profiles.default = {
      isDefault = true;
      search = {
        force = true;

        # DuckDuckGo has been excruciatingly awful lately
        default = "google";
      };

      settings = {
        # Normal firefox settings that happen to be blocked with policies
        "services.sync.declinedEngines" = "";

        "sidebar.verticalTabs" = true;
        "sidebar.main.tools" = "";
      };
    };
  };

  hm.home.file.".mozilla/firefox/profiles.ini".force = true;

  environment.variables.BROWSER = "firefox"; # `man` likes having this

  # Firefox cache in tmpfs (2GB should be plenty)
  fileSystems."/home/zeev/.cache/mozilla" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = [
      "defaults"
      "size=2G" # 2GB for Firefox cache
      "mode=0755"
      "uid=1000"
      "gid=100"
      "noatime" # No access time updates
      "nodev" # Security: no device files
      "nosuid" # Security: no suid binaries
    ];
  };

  # Optional: More aggressive tmpfs for all browser caches
  fileSystems."/home/zeev/.cache/chromium" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = [
      "defaults"
      "size=1G"
      "mode=0755"
      "uid=1000"
      "gid=100"
      "noatime"
    ];
  };

  # VS Code cache (those libuv workers writing heavily)
  fileSystems."/home/zeev/.cache/vscode-cpptools" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = [
      "defaults"
      "size=512M"
      "mode=0755"
      "uid=1000"
      "gid=100"
      "noatime"
    ];
  };

  # General /tmp with more space
  fileSystems."/tmp" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = [
      "defaults"
      "size=8G" # Generous /tmp space
      "mode=1777" # Sticky bit for multi-user
      "noatime"
    ];
  };
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 10; # Only 6.4GB - emergency only
  };

  systemd.user.tmpfiles.rules = [
    "d %h/.cache/mozilla 0755 zeev users 7d"
  ];
}
