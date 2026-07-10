# Development shells via flake-parts perSystem.
{inputs, ...}: {
  perSystem = {pkgs, ...}: {
    devShells = {
      default = import ../devshell.nix {
        inherit pkgs inputs;
        cachix.pull = ["4rmcyt"];
      };

      ide = import ../shells/ide.nix {
        inherit pkgs;
      };
    };
  };
}
