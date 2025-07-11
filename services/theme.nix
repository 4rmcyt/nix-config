{ stdenv, ... }:

stdenv.mkDerivation {
  name = "zeev-theme";
  src = ./keycloak-theme; # directory with your theme files
  installPhase = ''
    mkdir -p $out
    cp -r * $out/
  '';
}