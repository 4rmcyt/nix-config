# Shared shape for a single 4rmcyt cachix cache — used to compose
# nix.settings.extra-substituters / extra-trusted-public-keys per host
# without repeating the cachix.org URL/key boilerplate.
name: key: {
  extra-substituters = ["https://4rmcyt-${name}.cachix.org?priority=0"];
  extra-trusted-public-keys = ["4rmcyt-${name}.cachix.org-1:${key}"];
}
