{ pkgs }:
let
  themes = {
    b16 = {
      fg0 = "#181818";
      p0 = "#ff767a";
      p1 = "#ff9268";
      p2 = "#ffd254";
      p3 = "#86BBD8";
      p4 = "#45ace7";
      p5 = "#da84e4";
      green = "#80dc7e";
      purple = "#da84e4";
      red = "#ff767a";
    };
    pastel-powerline = {
      fg0 = "#fafefc";
      p0 = "#9A348E";
      p1 = "#DA627D";
      p2 = "#FCA17D";
      p3 = "#86BBD8";
      p4 = "#06969A";
      p5 = "#33658A";
      green = "#76D274";
      purple = "#9A348E";
      red = "#DA627D";
    };
    gruvbox-dark = {
      fg0 = "#fbf1c7";
      p0 = "#d65d0e";
      p1 = "#d79921";
      p2 = "#689d6a";
      p3 = "#458588";
      p4 = "#3c3836";
      p5 = "#665c54";
      green = "#76D274";
      purple = "#b16286";
      red = "#FF7078";
    };
  };
  mkConfig = c: {
    "$schema" = "https://starship.rs/config-schema.json";
    format = ''
      [](${c.p0})$os$username[](bg:${c.p1} fg:${c.p0})$directory[](fg:${c.p1} bg:${c.p2})$git_branch$git_status[](fg:${c.p2} bg:${c.p3})$nix_shell$docker_context$conda[](fg:${c.p3} bg:${c.p4})$c$rust$golang$nodejs$php$java$kotlin$haskell$python[](fg:${c.p4} bg:${c.p5})$time[ ](fg:${c.p5})
      $line_break$character
    '';
    # General
    line_break.disabled = true;
    character = {
      disabled = false;
      success_symbol = "[❯](bold fg:${c.green})";
      error_symbol = "[❯](bold fg:${c.red})";
      vimcmd_symbol = "[](bold fg:${c.green})";
      vimcmd_replace_one_symbol = "[](bold fg:${c.p0})";
      vimcmd_replace_symbol = "[](bold fg:${c.p0})";
      vimcmd_visual_symbol = "[](bold fg:${c.p3})";
    };

    # Symbols
    os = {
      disabled = false;
      style = "bg:${c.p0} fg:${c.fg0}";
      symbols = {
        Alpine = "";
        Amazon = "";
        Android = "";
        Arch = "󰣇";
        Artix = "󰣇";
        CentOS = "";
        Debian = "󰣚";
        Fedora = "󰣛";
        Gentoo = "󰣨";
        Linux = "󰌽";
        Macos = "󰀵";
        Manjaro = "";
        Mint = "󰣭";
        Raspbian = "󰐿";
        RedHatEnterprise = "󱄛";
        Redhat = "󱄛";
        SUSE = "";
        Ubuntu = "󰕈";
        Windows = "󰍲";
      };
    };
    time = {
      disabled = false;
      time_format = "%R";
      style = "bg:${c.p5}";
      format = "[[  $time ](fg:${c.fg0} bg:${c.p5})]($style)";
    };
    username = {
      show_always = true;
      style_user = "bg:${c.p0} fg:${c.fg0}";
      style_root = "bg:${c.p0} fg:${c.fg0}";
      format = "[ $user ]($style)";
    };
    directory = {
      style = "fg:${c.fg0} bg:${c.p1}";
      format = "[ $path ]($style)";
      truncation_length = 3;
      truncation_symbol = "…/";
      substitutions = {
        "Documents" = "󰈙 ";
        "Downloads" = " ";
        "Music" = "󰝚 ";
        "Pictures" = " ";
        "Developer" = "󰲋 ";
      };
    };
    git_branch = {
      symbol = "";
      style = "bg:${c.p2}";
      format = "[[ $symbol $branch ](fg:${c.fg0} bg:${c.p2})]($style)";
    };
    git_status = {
      style = "bg:${c.p2}";
      format =
        "[[($all_status$ahead_behind )](fg:${c.fg0} bg:${c.p2})]($style)";
    };
    nix_shell = {
      symbol = "󱄅";
      style = "bg:${c.p3}";
      format = "[[ $symbol( $name) ](fg:${c.fg0} bg:${c.p3})]($style)";
      heuristic = true;
    };
    docker_context = {
      symbol = "";
      style = "bg:${c.p3}";
      format = "[[ $symbol( $context) ](fg:${c.fg0} bg:${c.p3})]($style)";
    };
    conda = {
      style = "bg:${c.p3}";
      format = "[[ $symbol( $environment) ](fg:${c.fg0} bg:${c.p3})]($style)";
    };
    nodejs = {
      symbol = "";
      style = "bg:${c.p4}";
      format = "[[ $symbol( $version) ](fg:${c.fg0} bg:${c.p4})]($style)";
    };
    c = {
      symbol = " ";
      style = "bg:${c.p4}";
      format = "[[ $symbol( $version) ](fg:${c.fg0} bg:${c.p4})]($style)";
    };
    rust = {
      symbol = "";
      style = "bg:${c.p4}";
      format = "[[ $symbol( $version) ](fg:${c.fg0} bg:${c.p4})]($style)";
    };
    golang = {
      symbol = "";
      style = "bg:${c.p4}";
      format = "[[ $symbol( $version) ](fg:${c.fg0} bg:${c.p4})]($style)";
    };
    php = {
      symbol = "";
      style = "bg:${c.p4}";
      format = "[[ $symbol( $version) ](fg:${c.fg0} bg:${c.p4})]($style)";
    };
    java = {
      symbol = "";
      style = "bg:${c.p4}";
      format = "[[ $symbol( $version) ](fg:${c.fg0} bg:${c.p4})]($style)";
    };
    kotlin = {
      symbol = "";
      style = "bg:${c.p4}";
      format = "[[ $symbol( $version) ](fg:${c.fg0} bg:${c.p4})]($style)";
    };
    haskell = {
      symbol = "";
      style = "bg:${c.p4}";
      format = "[[ $symbol( $version) ](fg:${c.fg0} bg:${c.p4})]($style)";
    };
    python = {
      symbol = "";
      style = "bg:${c.p4}";
      format = "[[ $symbol( $version) ](fg:${c.fg0} bg:${c.p4})]($style)";
    };
  };
  starshipFinal = { theme }:
    let
      toml = (pkgs.formats.toml { }).generate "starship.toml" (mkConfig theme);
      bin = pkgs.writeShellScriptBin "ndstarship" ''
        export STARSHIP_CONFIG="${toml}"
        exec ${pkgs.starship}/bin/starship "$@"
      '';
    in pkgs.stdenvNoCC.mkDerivation {
      name = "ndstarship";
      src = null;
      dontUnpack = true;
      dontConfigure = true;
      dontBuild = true;
      installPhase = ''
        install -Dm644 ${toml}               $out/share/ndstarship/starship.toml
        install -Dm755 ${bin}/bin/ndstarship $out/bin/ndstarship
        ln      -s     $out/bin/ndstarship   $out/bin/starship
      '';
    };
in pkgs.lib.makeOverridable starshipFinal { theme = themes.b16; }
