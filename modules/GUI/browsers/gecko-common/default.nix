# Engine-level config shared by Gecko browsers (firefox, zen); browser UI prefs stay in each module
{lib}: {
  settings = import ./settings.nix;
  policies = import ./policies.nix;
  searchEngines = import ./search-engines.nix {inherit lib;};
}
