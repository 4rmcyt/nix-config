{lib, ...}: let
  # Minimal, CUT-ONLY EQ for the Grado SR325x, tuned for metal / punk where the
  # forward, aggressive Grado voicing is a feature, not a flaw. Cut-only means
  # no preamp headroom is needed and the loudness barely changes vs bypass
  # (only a sliver of energy above 11 kHz is removed), so A/B is fair.
  # It deliberately does NOT touch the 2-6 kHz guitar-presence region - just a
  # gentle shelf off the very top to tame splashy cymbals / sibilance on
  # hot/brickwalled masters. Too much? Bypass the equalizer, keep the crossfeed.
  preamp = 0.0;

  # type Fc(Hz) Gain(dB) Q
  bands = [
    ["Hi-shelf" 11000.0 (-1.5) 0.7]
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
      # hard-panned stereo mixes give on headphones. 700 Hz / 4.5 dB is the
      # bs2b "default" preset — the gentlest of the three built-ins.
      # bs2b attenuates internally (~2-3 dB) to keep headroom; output-gain
      # +2.5 dB makes up for that so enabled vs bypassed sit at the same
      # loudness. Fine-tune against the EasyEffects output meter if needed.
      "crossfeed#0" = {
        bypass = false;
        input-gain = 0.0;
        output-gain = 2.5;
        fcut = 700;
        feed = 4.5;
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
