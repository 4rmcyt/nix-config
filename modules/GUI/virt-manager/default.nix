{pkgs, ...}: {
  programs.virt-manager.enable = true;

  virtualisation = {
    podman.enable = true;
    libvirtd = {
      enable = true;
      qemu.vhostUserPackages = with pkgs; [virtiofsd];
    };
    spiceUSBRedirection.enable = true;
  };

  # libvirt's upstream unit hardcodes /usr/bin/sh which doesn't exist on NixOS.
  # Use systemd.units with raw drop-in text so ExecStart= (empty) clears the original
  # before setting ours — otherwise both run and /usr/bin/sh fails first.
  systemd.units."virt-secret-init-encryption.service" = {
    overrideStrategy = "asDropin";
    text = ''
      [Service]
      ExecStart=
      ExecStart=${pkgs.writeShellScript "virt-secret-init-encryption" ''
        umask 0077
        ${pkgs.coreutils}/bin/dd if=/dev/random status=none bs=32 count=1 | \
          ${pkgs.systemd}/bin/systemd-creds encrypt --name=secrets-encryption-key - \
          /var/lib/libvirt/secrets/secrets-encryption-key
      ''}
    '';
  };
}
