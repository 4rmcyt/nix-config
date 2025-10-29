{
  config,
  lib,
  ...
}: {
  options.roles.media-server = {
    enable = lib.mkEnableOption "media server role with media management services";
  };

  config = lib.mkIf config.roles.media-server.enable {
    # Ensure server role is enabled
    roles.server.enable = lib.mkDefault true;

    # Media-specific groups
    users.groups.media = {};

    # Common media directories
    systemd.tmpfiles.rules = [
      "d /data 755 root root -"
      "d /data/media 755 root media -"
      "d /data/media/movies 755 root media -"
      "d /data/media/tv 755 root media -"
      "d /data/media/music 755 root media -"
      "d /data/media/books 755 root media -"
      "d /data/media/audiobooks 755 root media -"
      "d /data/torrents 755 root media -"
    ];

    # Firewall rules for media services
    networking.firewall = {
      # Common media server ports will be opened by specific service modules
      allowedTCPPortRanges = [
        {
          from = 6881;
          to = 6889;
        } # BitTorrent
      ];
      allowedUDPPortRanges = [
        {
          from = 6881;
          to = 6889;
        } # BitTorrent
      ];
    };
  };
}
