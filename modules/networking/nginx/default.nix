_:
{
  # Allow Nginx to read the SSL certificates by adding its user to the 'acme' group.
  # The 'nginx' user is created automatically by the service module.
  users.users.nginx.extraGroups = [ "acme" ];

  # Open HTTP and HTTPS ports in the firewall.
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  # Configure the Nginx service.
  services.nginx = {
    enable = true;

    # These recommended settings are great for performance and security.
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    # This exposes a basic server status page, useful for monitoring.
    statusPage = true;
  };
}
