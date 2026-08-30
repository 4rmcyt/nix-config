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
      # hard-panned stereo mixes give on headphones. 600 Hz / 6.0 dB: a bit
      # warmer and more present than the "Chu Moy" preset (700/6.0), chosen by
      # ear on hard-panned metal/punk mixes.
      # bs2b attenuates internally to keep headroom; output-gain +1.0 dB makes
      # up for that so enabled vs bypassed sit at the same loudness (matched by
      # ear + EasyEffects output meter at fcut 600 / feed 6.0).
      "crossfeed#0" = {
        bypass = false;
        input-gain = 0.0;
        output-gain = 1.0;
        fcut = 600;
        feed = 6.0;
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
