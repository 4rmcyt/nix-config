# Base home-manager configuration applied to all hosts.
# Provides: sops, allowUnfree, overlays, stateVersion.
{
  config,
  inputs,
  ...
}: let
  inherit (config.meta) owner stateVersion;
in {
  modules.homeManager.base = {
    imports = [
      inputs.sops-nix.homeManagerModules.sops
    ];

    home = {
      inherit (owner) username;
      homeDirectory = "/home/${owner.username}";
      inherit stateVersion;
    };

    nixpkgs.config.allowUnfree = true;
    nixpkgs.overlays = [
      inputs.mcp-servers-nix.overlays.default
      inputs.nur.overlays.default
      inputs.nix-vscode-extensions.overlays.default
      (_final: prev: {
        mcp-server-fetch = prev.mcp-server-fetch.overrideAttrs (old: {
          postPatch =
            (old.postPatch or "")
            + ''
              substituteInPlace src/mcp_server_fetch/server.py \
                --replace-fail "AsyncClient(proxies=proxy_url)" "AsyncClient(proxy=proxy_url)"
            '';
        });
      })
    ];

    sops.age.keyFile = "/home/${owner.username}/.config/sops/age/keys.txt";

    xdg.userDirs.setSessionVariables = false;
  };
}
