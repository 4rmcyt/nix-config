{ config, pkgs, ... }:
{
  # Mandatory Access Control (AppArmor)
  security.apparmor = {
    enable = true;
    killUnconfinedConfinables = true;

    # Include additional profiles
    packages = with pkgs; [
      apparmor-profiles
      apparmor-utils
    ];

    # Custom profiles for services
    profiles = {
      # Nginx profile
      "${pkgs.nginx}/bin/nginx" = {
        extraConfig = ''
          #include <tunables/global>

          ${pkgs.nginx}/bin/nginx {
            #include <abstractions/base>
            #include <abstractions/nameservice>
            #include <abstractions/openssl>
            #include <abstractions/ssl_keys>
            
            capability setuid,
            capability setgid,
            capability net_bind_service,
            capability dac_override,
            
            /etc/nginx/** r,
            /var/log/nginx/** w,
            /var/lib/nginx/** rw,
            /run/nginx.pid w,
            
            # SSL certificates
            /var/lib/acme/** r,
            
            # Proxy backends
            network inet stream,
            network inet6 stream,
            
            # Deny everything else
            deny /** w,
          }
        '';
      };

      # SSH profile
      "${pkgs.openssh}/bin/sshd" = {
        extraConfig = ''
          #include <tunables/global>

          ${pkgs.openssh}/bin/sshd {
            #include <abstractions/base>
            #include <abstractions/nameservice>
            #include <abstractions/openssl>
            #include <abstractions/authentication>
            
            capability sys_chroot,
            capability setuid,
            capability setgid,
            capability net_bind_service,
            capability audit_write,
            
            /etc/ssh/** r,
            /etc/passwd r,
            /etc/group r,
            /etc/shadow r,
            /var/log/auth.log w,
            /var/empty/ r,
            
            # User home directories (restricted)
            owner /home/*/.ssh/ r,
            owner /home/*/.ssh/authorized_keys r,
            
            network inet stream,
            network inet6 stream,
            
            # Process creation
            /bin/bash ix,
            /usr/bin/zsh ix,
          }
        '';
      };
    };
  };

  # Kernel security modules
  boot = {
    kernelModules = [ "apparmor" ];

    kernelParams = [
      "apparmor=1"
      "security=apparmor"
      "lsm=landlock,lockdown,yama,integrity,apparmor,bpf"
    ];

    # Enable additional security features
    kernel.sysctl = {
      # AppArmor settings
      "kernel.apparmor_restrict_unprivileged_unconfined" = 1;

      # Additional LSM settings
      "kernel.yama.ptrace_scope" = 2; # More restrictive
    };
  };
}
