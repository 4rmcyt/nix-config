{pkgs, ...}: {
  programs.nautilus-open-any-terminal = {
    enable = true;
    terminal = "kitty";
  };

  services.gvfs.enable = true;

  environment.systemPackages = with pkgs; [
    nautilus
    gnome-autoar 
  ];
}
