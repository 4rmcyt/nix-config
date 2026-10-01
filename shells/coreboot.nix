# shell.nix
# NOTE we need mkShellNoCC
# mkShell would add the regular gcc, which has no ada (gnat)
# https://github.com/NixOS/nixpkgs/issues/142943
with import <nixpkgs> {};
  mkShellNoCC {
    buildInputs = [
      gnat14 # gcc with ada
      #gnatboot # gnat1
      ncurses # make menuconfig
      m4
      flex
      bison # Generate flashmap descriptor parser
      pkg-config
      #clang
      zlib
      acpica-tools # iasl
      qemu # test the image
      nasm
      python3
      flashrom
      pciutils
      me_cleaner
      curl
      ifdtool
      cbfstool
      intelmetool
      util-linux
    ];
    shellHook = ''
      # TODO remove?
      NIX_LDFLAGS="$NIX_LDFLAGS -lncurses"
      export NIX_LDFLAGS="$NIX_LDFLAGS -L${ncurses.out}/lib -lncurses"
      export NIX_CFLAGS_COMPILE="$NIX_CFLAGS_COMPILE -I${ncurses.dev}/include"
    '';
  }
