{pkgs, ...}: {
  programs.git = {
    enable = true;

    # Don't set global config that might expose info
    # userName = "Your Name";  # Move to user-specific config
    # userEmail = "email@example.com";  # Move to user-specific config

    extraConfig = {
      init.defaultBranch = "main";

      # Security settings
      core = {
        autocrlf = false;
        safecrlf = false;
        # Don't trust file modes from other systems
        filemode = false;
      };

      # Security: verify commits
      commit.gpgsign = true;
      tag.gpgsign = true;

      # Security: strict SSL
      http = {
        sslverify = true;
        cookiefile = "/dev/null"; # Disable cookie storage
      };

      # Security: disable automatic credential storage
      credential.helper = "";

      # Security: restrict protocols
      protocol = {
        allow = "never";
        git.allow = "user";
        http.allow = "user";
        https.allow = "user";
        ssh.allow = "user";
      };

      # Privacy: disable telemetry
      feature.manyFiles = false;

      # Security: GPG settings
      gpg.program = "${pkgs.gnupg}/bin/gpg";

      # Disable potentially dangerous features
      core.symlinks = false;
    };
  };
}
