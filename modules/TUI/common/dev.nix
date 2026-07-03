_: {
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  programs.rclone.enable = false;

  # SSH config managed at system level to avoid symlink permission issues
  programs.ssh.enable = false;

  # SSH handled by gpg-agent with enableSSHSupport
  services.ssh-agent.enable = false;
}
