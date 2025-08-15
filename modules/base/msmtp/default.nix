{
  config,
  lib,
  ...
}:
{
  sops.secrets = {
    msmtp_gmail_password = lib.mkDefault {
      sopsFile = ../../../secrets/gmail_conf.yaml;
      key = "gmail_password";
      owner = config.users.users.msmtp.name;
      group = config.users.groups.msmtp.name;
      mode = "0600";
    };
  };

  users.users.msmtp = {
    isSystemUser = true;
    group = "msmtp";
    description = "msmtp user for sending emails";
  };
  users.groups.msmtp = { };

  networking.firewall.allowedTCPPorts = [ 587 ]; # SMTP over SSL

  environment.etc."aliases" = {
    text = ''
      default: admin@example.com
    '';
    mode = "0644";
  };
  programs.msmtp = {
    enable = true;
    setSendmail = true;
    defaults = {
      aliases = "/etc/aliases";
      port = 587;
      tls = true;
      tls_certcheck = true; # Enabled by default, but good to be explicit
      tls_trust_file = "/etc/ssl/certs/ca-certificates.crt";
    };
    accounts = {
      default = {
        host = "smtp.gmail.com";
        auth = "on";
        passwordeval = "cat ${config.sops.secrets.msmtp_gmail_password.path}";
        user = "redacted@example.com";
        from = "redacted@example.com";
      };
    };
  };
}
