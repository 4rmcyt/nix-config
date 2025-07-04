{ stdenv, ... }:

stdenv.mkDerivation {
  name = "zeev-theme";
  src = ./keycloak-theme; # directory with your theme
  installPhase = ''
    mkdir -p $out
    cp -r * $out/
  '';
}

(final: prev: {
  custom_keycloak_themes = {
    zeev = prev.callPackage ./theme.nix { };
  };
})