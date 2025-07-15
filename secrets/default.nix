
let
  user-ed25519 = config.sops.secrets.zeev-ed25519.path;
  user-rsa = config.sops.secrets.zeev-rsa.path;
  user-keys = [ user-ed25519 user-rsa ];

  system-ed25519 = config.sops.secrets.homeserver-ed25519.path;
  system-rsa = config.sops.secrets.homeserver-rsa.path;
  system-keys = [ system-ed25519 system-rsa ];

  server-keys = system-keys ++ user-keys;
in {
  inherit user-keys system-keys server-keys;
}