{
  config,
  lib,
  pkgs,
  ...
}: {
  # Package overrides to fix build failures
  nixpkgs.overlays = [
    (final: prev: {
      # Fix audiobookshelf npm dependency issue
      # Error: npm ci fails due to package-lock.json mismatch with fsevents
      # Workaround: Use npm install instead of npm ci by making cache writable
      audiobookshelf = prev.audiobookshelf.overrideAttrs (oldAttrs: {
        makeCacheWritable = true;
        npmFlags = ["--legacy-peer-deps"];

        # Additional workaround: skip the failing npm ci step
        npmInstallFlags = ["--legacy-peer-deps"];

        # Override the build phase to use npm install instead of npm ci
        buildPhase = ''
          runHook preBuild

          # Use npm install instead of npm ci to avoid lock file issues
          npm install --legacy-peer-deps --offline --cache=$HOME/.npm
          npm run build --offline --cache=$HOME/.npm

          runHook postBuild
        '';
      });

      # Fix intel-compute-runtime-legacy1 missing cstdint header
      # Error: 'uint64_t' does not name a type - missing #include <cstdint>
      # Workaround: Add -include cstdint to CXXFLAGS to force include the header
      intel-compute-runtime-legacy1 = prev.intel-compute-runtime-legacy1.overrideAttrs (oldAttrs: {
        env = (oldAttrs.env or {}) // {
          CXXFLAGS = toString (
            (lib.splitString " " (oldAttrs.env.CXXFLAGS or ""))
            ++ ["-include" "cstdint"]
          );
        };
      });
    })
  ];
}
