{
  config,
  pkgs,
  lib,
  ...
}:

{ 
  unidecode-old = prev.python3Packages.unidecode.overrideAttrs (old: {
        pname = "Unidecode";
        version = "1.4.0";
        src = prev.fetchPypi {
          inherit pname version;
          hash = "sha256-c3c7606c27503ad8d501270406e345ddb480a7b5f38827eafe4fa82a137f0021";
        };
      });
  calibre-web = prev.calibre-web.overridePythonAttrs (old: {
        propagatedBuildInputs =
          (lib.filter (p: p.pname or "" != "unidecode") old.propagatedBuildInputs)
          ++ [ final.unidecode-old ];
      });
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
