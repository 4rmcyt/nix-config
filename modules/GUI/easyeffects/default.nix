_: let
  # Filters 1+6 of AutoEq's 10-band Rtings/B&K5128 correction; rest dropped as coupler artifacts.
  shokzOpenrunPro2Bands = {
    band0 = {
      type = "Lo-shelf";
      mode = "RLC (BT)";
      slope = "x1";
      solo = false;
      mute = false;
      frequency = 105.0;
      gain = 5.9;
      q = 0.7;
      width = 4.0;
    };
    band1 = {
      type = "Hi-shelf";
      mode = "RLC (BT)";
      slope = "x1";
      solo = false;
      mute = false;
      frequency = 10000.0;
      gain = 4.1;
      q = 0.7;
      width = 4.0;
    };
  };
in {
  # Generated with ASH-Toolset (https://github.com/ShanonPearce/ASH-Toolset), 48kHz/24-bit.
  # EasyEffects only finds impulses by ".irs" extension; ".wav" in the irs dir is silently ignored.
  xdg.dataFile = {
    "easyeffects/irs/brir-ash-listening-room.irs".source = ./brir-ash-listening-room.wav;
    "easyeffects/irs/hpcf-grado-sr325x.irs".source = ./hpcf-grado-sr325x.wav;

    # Captured from EasyEffects' Autoload UI — device/route strings aren't guessable.
    "easyeffects/autoload/output/bluez_output.A0_0C_E2_7B_7F_4A.1:Headphones.json".text = builtins.toJSON {
      device = "bluez_output.A0_0C_E2_7B_7F_4A.1";
      device-description = "OpenRun Pro 2 by Shokz";
      device-profile = "Headphones";
      preset-name = "shokz-openrun-pro2";
    };
  };

  services.easyeffects = {
    enable = true;
    preset.output = "grado-sr325x";

    extraPresets.grado-sr325x.output = {
      blocklist = [];
      plugins_order = ["convolver#0" "convolver#1"];

      # BRIR: ASH Listening Room AS-180, KEMAR HRTF, ±30° speakers, Flat target.
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

      # Headphone correction FIR: oratory1990 SR325x -> diffuse field.
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

    extraPresets.shokz-openrun-pro2.output = {
      blocklist = [];
      plugins_order = ["equalizer#0"];

      "equalizer#0" = {
        bypass = false;
        input-gain = -6.0;
        output-gain = 0.0;
        mode = "IIR";
        num-bands = 2;
        split-channels = false;
        balance = 0.0;
        pitch-left = 0.0;
        pitch-right = 0.0;
        left = shokzOpenrunPro2Bands;
        right = shokzOpenrunPro2Bands;
      };
    };
  };
}
