{ config, pkgs, lib, ... }:

{
  sops.secrets.keycloak_db_password = {
    owner = config.users.users.keycloak.name;
    group = config.users.groups.keycloak.name;
    mode = "0400";
  };

  services.postgresql = {
    enable = true;
    ensureDatabases = [ "keycloak" ];
    enableTCPIP = true;
    port = 5432;
    ensureUsers = [
      {
        name = "keycloak";
        ensureDBOwnership = true;
      }
    ];
    authentication = pkgs.lib.mkOverride 10 ''
      #type  database    user        address        method
      local  all         all                        peer
      host   all         all         127.0.0.1/32   scram-sha-256
      host   all         all         ::1/128        scram-sha-256
    '';
  };

  services.keycloak = {
    enable = true;
    database = {
      type = "postgresql";
      username = "keycloak";
      passwordFile = config.sops.secrets.keycloak_db_password.path;
      host = "localhost";
      port = 5432;
      name = "keycloak";
    };
    settings = {
      hostname = "keycloak.labhome.work";
      proxy-headers = "xforwarded";
      http-enabled = true;
      http-port = 8080;
      "log-level" = "info";
      
      # Enable YubiKey/WebAuthn features
      features = "preview,authorization,admin-fine-grained-authz,recovery-codes,update-email,declarative-user-profile,webauthn";
      
      # Additional settings for YubiKey support
      spi-truststore-file-file = "/etc/ssl/certs/ca-certificates.crt";
      spi-truststore-file-password = "changeit";
      spi-truststore-file-hostname-verification-policy = "WILDCARD";
    };
    
    # Add YubiKey provider JAR to classpath
    extraJvmOpts = [
      "-Djboss.modules.system.pkgs=org.jboss.byteman,com.yubico"
    ];
  };

  # Install YubiKey libraries and tools
  environment.systemPackages = with pkgs; [
    yubikey-manager
    yubikey-personalization
    yubioath-flutter
    pcsclite
    ccid
  ];

  # Enable PC/SC daemon for smart card support
  services.pcscd = {
    enable = true;
    plugins = [ pkgs.ccid ];
  };

  # Enable udev rules for YubiKey
  services.udev.packages = with pkgs; [
    yubikey-personalization
    libu2f-host
  ];

  # Add YubiKey support groups
  users.groups.yubikey = {};
  
  # Ensure the keycloak user can access YubiKey devices
  users.users.keycloak.extraGroups = [ "yubikey" ];

  # Custom udev rules for YubiKey access
  services.udev.extraRules = ''
    # YubiKey rules for keycloak service
    SUBSYSTEM=="usb", ATTRS{idVendor}=="1050", ATTRS{idProduct}=="0010|0110|0111|0114|0116|0401|0403|0405|0407|0410", GROUP="yubikey", MODE="0664"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="1050", ATTRS{idProduct}=="0020|0120|0121|0200|0402|0404|0406|0408|0411", GROUP="yubikey", MODE="0664"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="1050", ATTRS{idProduct}=="0030|0130|0131|0140|0210|0403|0405|0407|0410", GROUP="yubikey", MODE="0664"
  '';
}