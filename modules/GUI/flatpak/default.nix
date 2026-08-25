{
  inputs,
  pkgs,
  ...
}: {
  imports = [inputs.nix-flatpak.nixosModules.nix-flatpak];

  services.flatpak = {
    enable = true;
    packages = [
      "com.github.IsmaelMartinez.teams_for_linux"
      "com.heroicgameslauncher.hgl"
    ];
  };

  systemd.services.flatpak-repo = {
    wantedBy = ["multi-user.target"];
    after = ["network-online.target"];
    wants = ["network-online.target"];
    path = [pkgs.flatpak];
    script = ''
      flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
      flatpak remote-add --if-not-exists flathub-beta https://dl.flathub.org/beta-repo/flathub-beta.flatpakrepo
    '';
  };
}
