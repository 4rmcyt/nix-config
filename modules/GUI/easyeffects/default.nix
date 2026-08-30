_: {
  # Grado SR325x output chain, generated with ASH-Toolset (https://github.com/ShanonPearce/ASH-Toolset):
  #
  #   convolver#0  - BRIR true-stereo impulse (ASH Listening Room AS-180, KEMAR HRTF,
  #                  ±30° speakers, +3 dB direct sound, Flat room target). Turns the
  #                  headphones into a pair of speakers in a small room: out-of-head
  #                  imaging + crossfeed + early reflections. Replaces the old bs2b.
  #   convolver#1  - headphone correction FIR (oratory1990 SR325x -> diffuse field).
  #                  Neutralises the headphone's own response so the BRIR's tuning
  #                  lands correctly. Replaces the old parametric equalizer.
  #
  # Both IRs are 48 kHz / 24-bit; autogain keeps enabled vs bypassed level-matched.
  # Regenerate: run ASH-Toolset, export "WAV Stereo FIR Filters" + "True Stereo WAV
  # BRIRs" at 48/24, drop the two wavs back in this directory under the same names.
  # EasyEffects only looks up impulses by the ".irs" extension (an .irs file is
  # just a renamed WAV); a plain .wav in the irs dir is never found.
  xdg.dataFile = {
    "easyeffects/irs/brir-ash-listening-room.irs".source = ./brir-ash-listening-room.wav;
    "easyeffects/irs/hpcf-grado-sr325x.irs".source = ./hpcf-grado-sr325x.wav;
  };

  services.easyeffects = {
    enable = true;
    preset.output = "grado-sr325x";

    extraPresets.grado-sr325x.output = {
      blocklist = [];
      plugins_order = ["convolver#0" "convolver#1"];

      "convolver#0" = {
        bypass = false;
        input-gain = 0.0;
        output-gain = 0.0;
        kernel-name = "brir-ash-listening-room";
        ir-width = 100;
        autogain = true;
        dry = -100.0;
        wet = 0.0;
      };

      "convolver#1" = {
        bypass = false;
        input-gain = 0.0;
        output-gain = 0.0;
        kernel-name = "hpcf-grado-sr325x";
        ir-width = 100;
        autogain = true;
        dry = -100.0;
        wet = 0.0;
      };
    };
  };
}
