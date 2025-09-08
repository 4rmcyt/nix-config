# shell.nix

# NOTE we need mkShellNoCC
# mkShell would add the regular gcc, which has no ada (gnat)
# https://github.com/NixOS/nixpkgs/issues/142943

with import <nixpkgs> { };
mkShellNoCC {
  buildInputs = [
    gnat11 # gcc with ada
    #gnatboot # gnat1
    ncurses # make menuconfig
    m4 flex bison # Generate flashmap descriptor parser
    #clang
    zlib
    #acpica-tools # iasl
    pkgconfig
    qemu # test the image
  ];
  shellHook = ''
    # TODO remove?
    NIX_LDFLAGS="$NIX_LDFLAGS -lncurses"
  '';
}