{ lib, config, ... }:
{
  imports = [
    ./homepage
    ./miniflux
    ./microbin
    ./paperless
    ./radicale
    ./home-assistant
    ./nixarr
    ./kavita
    ./calibre-web
    # ./vaultwarden
    # ./linkwarden
  ];
}
