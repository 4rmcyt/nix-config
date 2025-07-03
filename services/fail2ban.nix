# { config, pkgs, ... }:

# {
#   # SOPS secrets for Cloudflare API
#   sops.secrets.cloudflare_api_key = { };
#   sops.secrets.cloudflare_zone_id = { };

#   services.fail2ban = {
#     enable = true;
#     maxretry = 5;
    
#     extraPackages = [
#       pkgs.curl
#       pkgs.jq
#     ];
    
#     ignoreIP = [
#       "127.0.0.0/8"
#       "10.0.0.0/8"
#       "192.168.0.0/16"
#       "172.16.0.0/12"
#       # Cloudflare IP ranges - don't ban Cloudflare IPs
#       "173.245.48.0/20"
#       "103.21.244.0/22"
#       "103.22.200.0/22"
#       "103.31.4.0/22"
#       "141.101.64.0/18"
#       "108.162.192.0/18"
#       "190.93.240.0/20"
#       "188.114.96.0/20"
#       "197.234.240.0/22"
#       "198.41.128.0/17"
#       "162.158.0.0/15"
#       "104.16.0.0/13"
#       "104.24.0.0/14"
#       "172.64.0.0/13"
#       "131.0.72.0/22"
#     ];
    
#     bantime = "1h";
#     bantime-increment = {
#       enable = true;
#       multipliers = "1 2 4 8 16 32 64";
#       maxtime = "168h";
#       overalljails = true;
#     };
    
#     jails = {
#       # SSH jail with Cloudflare action
#       ssh = {
#         settings = {
#           enabled = true;
#           filter = "sshd";
#           logpath = "/var/log/auth.log";
#           maxretry = 3;
#           bantime = "1h";
#           findtime = "10m";
#           action = "cloudflare-token";
#         };
#       };
      
#       # Home Assistant failed logins
#       homeassistant = {
#         settings = {
#           enabled = true;
#           backend = "systemd";
#           journalmatch = "_SYSTEMD_UNIT=home-assistant.service";
#           filter = "homeassistant";
#           maxretry = 5;
#           findtime = "10m";
#           bantime = "1h";
#           action = "cloudflare-token";
#         };
#       };
      
#       # Nextcloud failed logins  
#       nextcloud = {
#         settings = {
#           enabled = true;
#           backend = "systemd";
#           journalmatch = "_SYSTEMD_UNIT=nextcloud-*";
#           filter = "nextcloud";
#           maxretry = 5;
#           findtime = "10m";
#           bantime = "1h";
#           action = "cloudflare-token";
#         };
#       };
      
#       # Keycloak failed logins
#       keycloak = {
#         settings = {
#           enabled = true;
#           backend = "systemd";
#           journalmatch = "_SYSTEMD_UNIT=keycloak.service";
#           filter = "keycloak";
#           maxretry = 3;
#           findtime = "10m";
#           bantime = "2h";
#           action = "cloudflare-token";
#         };
#       };
      
#       # Jellyfin failed logins
#       jellyfin = {
#         settings = {
#           enabled = true;
#           backend = "systemd";
#           journalmatch = "_SYSTEMD_UNIT=jellyfin.service";
#           filter = "jellyfin";
#           maxretry = 5;
#           findtime = "10m";
#           bantime = "30m";
#           action = "cloudflare-token";
#         };
#       };
#     };
#   };

#   # Create custom filters for each service
#   environment.etc = {
#     # Home Assistant filter
#     "fail2ban/filter.d/homeassistant.conf".text = ''
#       [Definition]
#       failregex = Login attempt or request with invalid authentication from <HOST>
#                   Invalid authentication.*from <HOST>
#       ignoreregex =
#     '';
    
#     # Nextcloud filter
#     "fail2ban/filter.d/nextcloud.conf".text = ''
#       [Definition]
#       failregex = Login failed:.*remoteAddr:<HOST>
#                   Brute force attempt.*remoteAddr:<HOST>
#                   Invalid credentials.*remoteAddr:<HOST>
#       ignoreregex =
#     '';
    
#     # Keycloak filter
#     "fail2ban/filter.d/keycloak.conf".text = ''
#       [Definition]
#       failregex = type=LOGIN_ERROR.*realmId=.*clientId=.*userId=.*ipAddress=<HOST>
#                   Invalid user credentials.*clientIP=<HOST>
#       ignoreregex =
#     '';
    
#     # Jellyfin filter
#     "fail2ban/filter.d/jellyfin.conf".text = ''
#       [Definition]
#       failregex = Authentication request for .* has been denied \(IP: <HOST>\)
#                   Invalid login attempt.*IP:<HOST>
#       ignoreregex =
#     '';

#     # Cloudflare action configuration
#     "fail2ban/action.d/cloudflare-token.conf".text =
#       let
#         notes = "Fail2Ban-${config.networking.hostName}";
#         cfapi = "https://api.cloudflare.com/client/v4/zones/$(cat ${config.sops.secrets.cloudflare_zone_id.path})/firewall/access_rules/rules";
#       in
#       ''
#         [Definition]
#         actionstart =
#         actionstop =
#         actioncheck =
        
#         actionunban = id=$(curl -s -X GET "${cfapi}" \
#             -H "Authorization: Bearer $(cat ${config.sops.secrets.cloudflare_api_key.path})" \
#             -H "Content-Type: application/json" \
#             | jq -r '.result[] | select(.notes == "${notes}" and .configuration.target == "ip" and .configuration.value == "<ip>") | .id')
#             if [ -z "$id" ]; then echo "ID for <ip> not found"; exit 0; fi; \
#             curl -s -X DELETE "${cfapi}/$id" \
#                 -H "Authorization: Bearer $(cat ${config.sops.secrets.cloudflare_api_key.path})" \
#                 -H "Content-Type: application/json"
        
#         actionban = curl -s -X POST "${cfapi}" \
#             -H "Authorization: Bearer $(cat ${config.sops.secrets.cloudflare_api_key.path})" \
#             -H "Content-Type: application/json" \
#             --data '{"mode":"block","configuration":{"target":"ip","value":"<ip>"},"notes":"${notes}"}'
        
#         [Init]
#         name = cloudflare-token
#       '';
#   };
# }


{ config, pkgs, ... }:

{
  services.fail2ban = {
    enable = true;
    maxretry = 5;
    ignoreIP = [
      "127.0.0.0/8"
      "10.0.0.0/8"
      "172.16.0.0/12"
      "192.168.0.0/16"
    ];
  };
}