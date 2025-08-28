{ pkgs, ... }:
{
  # CRITICAL FIX: Set primary group explicitly
  users.users.calibre-web = {
    isSystemUser = true;
    group = "calibre-web"; # This was missing - primary group
    extraGroups = [
      "media" # Remove "users" and "calibre-web" from extraGroups
    ];
  };
  users.groups.calibre-web = { };

  networking.firewall.allowedTCPPorts = [
    8083 # Calibre-Web
  ];

  # Ensure directories exist with correct permissions
  systemd.tmpfiles.rules = [
    "d /data/media/books 0755 calibre-web calibre-web - -"
    "d /var/lib/calibre-web 0755 calibre-web calibre-web - -"
  ];

  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    virtualHosts."calibre-web.example.com" = {
      forceSSL = true;
      sslCertificate = "/var/lib/acme/example.com/fullchain.pem";
      sslCertificateKey = "/var/lib/acme/example.com/key.pem";

      locations."/" = {
        proxyPass = "http://127.0.0.1:8083"; # Use 127.0.0.1 instead of localhost
        proxyWebsockets = true;
        extraConfig = ''
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
          proxy_set_header X-Script-Name $request_uri;
        '';
      };
    };
  };

  # REMOVE this line - the service provides calibre-web automatically
  # environment.systemPackages = [ pkgs.calibre-web ];

  services.calibre-web = {
    enable = true;
    listen = {
      port = 8083;
      ip = "127.0.0.1";
    };
    options = {
      enableBookConversion = true;
      enableBookUploading = true;
      calibreLibrary = "/data/media/books";
    };
  };

  # Optional: Add calibre for book conversion tools
  environment.systemPackages = with pkgs; [
    calibre # Provides ebook-convert and other conversion tools
  ];
}
