{
  config,
  pkgs,
  lib,
  ...
}:

{ 
   nixpkgs.overlays = [
    (final: prev: {
      # 1. Define an older version of unidecode that calibre-web requires.
      unidecode-old = prev.python3Packages.unidecode.overrideAttrs (old: {
        pname = "Unidecode";
        version = "1.3.8";
        src = prev.fetchPypi {
          pname = "Unidecode";
          version = "1.3.8";
          # This is the hash for Unidecode version 1.3.8
          hash = "sha256-g6INa29SHqg3oFVl2g5GUdCWRrp8qNOYVwYq25f3i+4=";
        };
      });

      # 2. Override the calibre-web package to use the older unidecode.
      calibre-web = prev.calibre-web.overridePythonAttrs (old: {
        propagatedBuildInputs =
          # Remove the default (incompatible) unidecode package from the build inputs.
          # We also provide a default empty list in case propagatedBuildInputs doesn't exist.
          (lib.filter (p: p.pname or "" != "unidecode") (old.propagatedBuildInputs or []))
          # Add the older, compatible version we defined above.
          ++ [ final.unidecode-old ];
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
      calibreLibrary = "/data/media/books";
    };
  };
}
