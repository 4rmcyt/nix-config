_inputs: [
  # cuda-redist fixup crashes under __structuredAttrs (nixpkgs#323126/#422989); patch buildRedist so it covers all of cudaPackages
  (_final: prev: {
    cudaPackages = prev.cudaPackages.overrideScope (_cfinal: cprev: {
      buildRedist = args: (cprev.buildRedist args).overrideAttrs (_old: {__structuredAttrs = false;});
    });
  })

  # intel-compute-runtime-legacy1 fails under gcc-16's -Werror=sfinae-incomplete (no upstream fix)
  (_final: prev: {
    intel-compute-runtime-legacy1 = prev.intel-compute-runtime-legacy1.overrideAttrs (old: {
      NIX_CFLAGS_COMPILE = toString (old.NIX_CFLAGS_COMPILE or "") + " -Wno-error=sfinae-incomplete";
    });
  })
]
