{ config, pkgs, lib, ... }:

{
  # Enable YubiKey support system-wide
  services.pcscd.enable = true;
  services.udev.packages = with pkgs; [
    yubikey-personalization
    libu2f-host
    yubikey-manager
  ];

  # Install YubiKey management tools
  environment.systemPackages = with pkgs; [
    yubikey-manager
    yubikey-personalization
    yubioath-flutter
    pcsclite
    ccid
    libfido2
    pam_u2f
  ];

  # Enable U2F/FIDO2 support
  security.pam.u2f = {
    enable = true;
    settings = {
      cue = true;
      debug = false;
    };
  };

  # YubiKey udev rules
  services.udev.extraRules = ''
    # YubiKey USB rules
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1050", TAG+="uaccess", GROUP="users", MODE="0664"
    
    # YubiKey 5 Series
    SUBSYSTEM=="usb", ATTR{idVendor}=="1050", ATTR{idProduct}=="0407", TAG+="uaccess", GROUP="users", MODE="0664"
    SUBSYSTEM=="usb", ATTR{idVendor}=="1050", ATTR{idProduct}=="0410", TAG+="uaccess", GROUP="users", MODE="0664"
    
    # YubiKey 4 Series
    SUBSYSTEM=="usb", ATTR{idVendor}=="1050", ATTR{idProduct}=="0406", TAG+="uaccess", GROUP="users", MODE="0664"
    SUBSYSTEM=="usb", ATTR{idVendor}=="1050", ATTR{idProduct}=="0408", TAG+="uaccess", GROUP="users", MODE="0664"
    
    # Security Key Series
    SUBSYSTEM=="usb", ATTR{idVendor}=="1050", ATTR{idProduct}=="0120", TAG+="uaccess", GROUP="users", MODE="0664"
  '';

  # Create yubikey group
  users.groups.yubikey = {};
}