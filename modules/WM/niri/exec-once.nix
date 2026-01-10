{lib, ...}: {
  programs.niri.settings = {
    spawn-at-startup = lib.mkForce [
      {
        command = [
          "wl-paste"
          "--type"
          "text"
          "--watch"
          "cliphist"
          "store"
        ];
      }
      {
        command = [
          "wl-paste"
          "--type"
          "image"
          "--watch"
          "cliphist"
          "store"
        ];
      }
      {
        command = [
          "wl-clip-persist"
          "--clipboard"
          "both"
        ];
      }
      {
        command = [
          "xwayland-satellite"
          ":0"
        ];
      }
    ];
  };
}
