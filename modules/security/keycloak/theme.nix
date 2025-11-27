{stdenv}:
stdenv.mkDerivation {
  pname = "keycloak_theme_custom";
  version = "1.0";

  src = ./themes/custom;

  buildInputs = [];
  nativeBuildInputs = [];

  installPhase = ''
    mkdir -p $out
    cp -a login $out
  '';
}
