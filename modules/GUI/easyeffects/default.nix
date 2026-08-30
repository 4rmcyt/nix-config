{lib, ...}: let
  # AutoEq — oratory1990, Harman over-ear 2018 target
  # Source: results/oratory1990/over-ear/Grado SR325x/Grado SR325x ParametricEQ.txt
  # https://github.com/jaakkopasanen/AutoEq
  #
  # Tames the SR325x's signature upper-mid glare (2.1 kHz dip, 10 kHz shelf cut)
  # while filling in the sub-bass the open Grado design rolls off. The AutoEq
  # preamp of -6.9 dB is applied as the equalizer input-gain so nothing clips.
  preamp = -6.9;

  # type Fc(Hz) Gain(dB) Q
  bands = [
    ["Lo-shelf" 105.0 8.1 0.7]
    ["Bell" 85.0 (-5.9) 0.52]
    ["Bell" 6174.0 4.7 2.45]
    ["Bell" 3352.0 5.4 3.57]
    ["Bell" 2117.0 (-5.2) 5.27]
    ["Hi-shelf" 10000.0 (-2.3) 0.7]
    ["Bell" 8641.0 2.1 3.55]
    ["Bell" 4530.0 (-1.8) 6.0]
    ["Bell" 39.0 1.4 3.98]
    ["Bell" 55.0 (-0.6) 1.87]
  ];

  mkBand = i: b: {
    name = "band${toString i}";
    value = {
      type = builtins.elemAt b 0;
      mode = "RLC (BT)";
      slope = "x1";
      solo = false;
      mute = false;
      frequency = builtins.elemAt b 1;
      gain = builtins.elemAt b 2;
      q = builtins.elemAt b 3;
      width = 4.0;
    };
  };

  channel = builtins.listToAttrs (lib.imap0 mkBand bands);
in {
  services.easyeffects = {
    enable = true;
    preset.output = "grado-sr325x";

    extraPresets.grado-sr325x.output = {
      blocklist = [];
      plugins_order = ["equalizer#0" "crossfeed#0"];

      # bs2b crossfeed — kills the "sound stuck inside your head" effect that
      # hard-panned stereo mixes give on headphones. fcut 700 Hz / feed 5.5 dB
      # is between the bs2b "default" (700/4.5) and "Chu Moy" (700/6.0) presets.
      "crossfeed#0" = {
        bypass = false;
        input-gain = 0.0;
        output-gain = 0.0;
        fcut = 700;
        feed = 5.5;
      };

      "equalizer#0" = {
        bypass = false;
        input-gain = preamp;
        output-gain = 0.0;
        mode = "IIR";
        num-bands = builtins.length bands;
        split-channels = false;
        balance = 0.0;
        pitch-left = 0.0;
        pitch-right = 0.0;
        left = channel;
        right = channel;
      };
    };
  };
}
