{
  config,
  pkgs,
  lib,
  ...
}:
{
  nixpkgs.overlays = [
  (final: prev: {
    # Override the calibre-web package
    calibre-web = prev.calibre-web.overrideAttrs (oldAttrs: {
      # Add a post-patch step to modify the dependency list
      postPatch = (oldAttrs.postPatch or "") + ''
        # Find the requirements file and relax the unidecode version pin
        substituteInPlace ./requirements.txt \
          --replace "unidecode<1.4.0" "unidecode<=1.4.0"
      '';
    });
  })
];
  services.calibre-web = {
    enable = true;
    listen = {
      port = 8083;
      ip = "127.0.0.1";
    };
    options = {
      enableBookConversion = true;
      enableKepubify = true;
      calibreLibrary = "/data/media/books";
    };
  };
}
