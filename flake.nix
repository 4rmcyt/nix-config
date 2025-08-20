{
  description = "NixOS configuration";

  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://nix-gaming.cachix.org"
      "https://hyprland.cachix.org"
      "https://homeserver.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "homeserver.cachix.org-1:0vStm6koDUwET/iWYhbKpsuVO4v3UgN3510zYH9YpZU="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils?shallow=true";

    cpu-microcodes = {
      url = "github:platomav/CPUMicrocodes";
      flake = false;
    };

    auto-cpufreq.url = "github:AdnanHodzic/auto-cpufreq";
    auto-cpufreq.inputs.nixpkgs.follows = "nixpkgs";

    # NixOS-specific inputs
    linkwarden-pr = {
      url = "github:NixOS/nixpkgs/f0809e9f3402644c0987842727cb1d3f93d2e4a6?shallow=1";
      flake = false;
    };
    nixos-facter-modules.url = "github:nix-community/nixos-facter-modules";
    nixos-needsreboot.url = "https://flakehub.com/f/thefossguy/nixos-needsreboot/*.tar.gz";
    vscode-server.url = "github:nix-community/nixos-vscode-server";
    nixarr.url = "github:rasmus-kirk/nixarr";
    nixos-generators.url = "github:nix-community/nixos-generators";
    authentik-nix.url = "github:nix-community/authentik-nix";

    hyprland.url = "github:hyprwm/Hyprland";
    hypr-contrib.url = "github:hyprwm/contrib";
    hyprpicker.url = "github:hyprwm/hyprpicker";
    hyprlock.url = "github:hyprwm/hyprlock";
    waybar.url = "github:Alexays/Waybar";
    nix-gaming.url = "github:fufexan/nix-gaming";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-ld = {
      url = "github:Mic92/nix-ld";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Common inputs
    treefmt-nix.url = "github:numtide/treefmt-nix";
    systems.url = "github:nix-systems/default";

    # REMOVED: Unused 'agenix' input
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

#   outputs =
#     {
#       self,
#       nixpkgs,
#       sops-nix,
#       vscode-server,
#       disko,
#       home-manager,
#       nix-index-database,
#       nixvim,
#       nixarr,
#       authentik-nix,
#       treefmt-nix,
#       auto-cpufreq,
#       systems,
#       ...
#     }@inputs:
#     let
#       system = "x86_64-linux";
#       eachSystem = f: nixpkgs.lib.genAttrs (import systems) (system: f nixpkgs.legacyPackages.${system});
#       treefmtEval = eachSystem (pkgs: treefmt-nix.lib.evalModule pkgs ./treefmt.nix);

#       # This list contains modules common to all your NixOS systems.
#       commonNixOSModules = [
#         sops-nix.nixosModules.sops
#         { sops.age.keyFile = "/var/lib/sops/age.key"; }
#         home-manager.nixosModules.home-manager
#         disko.nixosModules.disko
#         nix-index-database.nixosModules.nix-index
#         auto-cpufreq.nixosModules.default
#          "${inputs.linkwarden-pr}/nixos/modules/services/web-apps/linkwarden.nix"
#         inputs.nixos-facter-modules.nixosModules.facter
#         { facter.reportPath = ./facter.json; }
#       ];

#       nixosHomeManagerConfig = user: host: {
#         home-manager.useGlobalPkgs = true;
#         home-manager.useUserPackages = true;
#         home-manager.users.${user} = {
#           imports = [
#             ./modules/home-manager/${host}
#             sops-nix.homeManagerModules.sops
#           ];
#           sops.age.keyFile = "/home/zeev/.config/sops/age/keys.txt";
#         };
#       };
#     in
#     {
#       formatter = eachSystem (pkgs: treefmtEval.${pkgs.system}.config.build.wrapper);
#       # for `nix flake check`
#       checks = eachSystem (pkgs: {
#         formatting = treefmtEval.${pkgs.system}.config.build.check self;
#       });

#       nixosConfigurations = {
#         homeserver = nixpkgs.lib.nixosSystem {
#           inherit system;
#           specialArgs = {
#             inherit self inputs;
#             host = "homeserver";
#           };

#           modules = commonNixOSModules ++ [
#             ./hosts/nixos/homeserver
#             ./modules/users/zeev
#             ./modules/disko
#             (nixosHomeManagerConfig "zeev" "homeserver")
#             nixarr.nixosModules.default
#             authentik-nix.nixosModules.default
#             vscode-server.nixosModules.default
#           ];
#         };
#       };
#     };
# }
 outputs =
    { flake-utils, nixpkgs, ... }@inputs:
    let
      helpers = import ./flakeHelpers.nix inputs;
      inherit (helpers) mkMerge mkNixos mkDarwin;
    in
    mkMerge [
      (flake-utils.lib.eachDefaultSystem (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          packages.default = pkgs.mkShell {
            packages = [
              pkgs.just
              pkgs.nixos-rebuild-ng
            ];
          };
        }
      ))
      (mkNixos "homeserver" inputs.nixpkgs [
        ./modules/notthebe.ee
        ./homelab
        inputs.home-manager.nixosModules.home-manager
      ])

      (mkDarwin "macbook" inputs.nixpkgs
        [
          dots/tmux
          dots/kitty
        ]
        [ ]
      )
    ];
}