{ config, pkgs, ... }:

{
  services.udev.packages = [ pkgs.yubikey-personalization ];
  
  services.pcscd.enable = true;
  
  # Install only CLI YubiKey tools (no GUI)
  environment.systemPackages = with pkgs; [
    yubikey-personalization      # CLI tool
    yubikey-manager             # CLI tool
    yubico-piv-tool            # CLI tool
  ];

  # Security services
  security.polkit.enable = true;
  
  # Add udev rules for YubiKey
  services.udev.extraRules = ''
    # YubiKey rules
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1050", ATTRS{idProduct}=="0113|0114|0115|0116|0120|0200|0402|0403|0406|0407|0410", TAG+="uaccess"
  '';
}