final: _prev: {
  claw-code = final.rustPlatform.buildRustPackage {
    pname = "claw-code";
    version = "0.1.0";

    src = final.fetchFromGitHub {
      owner = "ultraworkers";
      repo = "claw-code";
      rev = "aee5263aefcb460f4b051baef7008400a5a0db2b";
      hash = "sha256-NErbWplKiWoG4LWJmqa+G2JnCoI9fDMCk0LneSq+Ntw=";
    };

    sourceRoot = "source/rust";

    cargoHash = "sha256-P8QqUM1s/fNv7Fb4dmpJWDfTNumgUu1Cdiln8ybSDUU=";

    doCheck = false;

    buildInputs = final.lib.optionals final.stdenv.isLinux [
      final.openssl
    ];

    nativeBuildInputs = [
      final.pkg-config
    ];

    env.OPENSSL_NO_VENDOR = 1;

    meta = {
      description = "Claw Code — open-source Rust CLI agent harness (Claude Code parity)";
      homepage = "https://github.com/ultraworkers/claw-code";
      license = final.lib.licenses.mit;
      mainProgram = "claw";
    };
  };
}
