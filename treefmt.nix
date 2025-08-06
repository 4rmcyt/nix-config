{ pkgs, ... }:
{
  # Used to find the project root
  projectRootFile = "flake.nix";

  # Files to exclude from formatting.
  settings.global.excludes = [
    # Generated files
    "build/**"
    "tools/**"

    # Exclude non-Nix code for now.
    "**/.editorconfig"
    "**/.gitattributes"
    "**/.gitignore"
    "**/.clang-format"
    "LICENSE"
    "**/LICENSE"
    "**/LICENSE.MIT"
    "**/AUTHORS"
    "*.c"
    "*.h"
    "*.cpp"
    "*.hpp"
    "*.ui"
    "*.qml"
    "*.pri"
    "*.qrc"
    "*.pro"
    "*.png"
    "*.jpg"
    "*.svg"
    "*.json"
    "*.bin"
    "*.ttf"
    "*.md"
    "*.xml"
    "*.lbm"
    "*.yml"
    "*.conf"
    "*.txt"
    "*.sh"
    "*.plist"
    # spell-checker: disable-next-line
    "qmarkdowntextedit/trans/**"
    "*.pc.in"
    "build_*"
    "*.storyboard"
    "ios/iTunesArtwork"
    "ios/iTunesArtwork@2x"
    "*.mm"
    "*.icns"
    "**/HUFFCODE"
    "QCodeEditor/include/**"
    "*.in"
    "*.gradle"
    "*.java"
    "*.jar"
    "*.properties"
    "**/gradlew"
    "application/create_app"
  ];

  programs.deadnix.enable = true;
  programs.deno.enable = pkgs.hostPlatform.system != "riscv64-linux";
  programs.mdsh.enable = true;
  programs.nixfmt.enable = true;
  programs.shellcheck.enable = pkgs.hostPlatform.system != "riscv64-linux";
  programs.shfmt.enable = pkgs.hostPlatform.system != "riscv64-linux";
  programs.yamlfmt.enable = true;

  programs.treefmt.enable = true;
  programs.treefmt.settings = {
    nix = {
      command = "nixfmt";
      options = [
        "-sv"
        "-w"
        "80"
      ];
      includes = [ "*.nix" ];
      excludes = [ ];
    };
  };

}
