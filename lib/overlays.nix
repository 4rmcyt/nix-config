_inputs: [
  # intel-compute-runtime-legacy1 fails under gcc-16's -Werror=sfinae-incomplete (no upstream fix)
  (_final: prev: {
    intel-compute-runtime-legacy1 = prev.intel-compute-runtime-legacy1.overrideAttrs (old: {
      NIX_CFLAGS_COMPILE = toString (old.NIX_CFLAGS_COMPILE or "") + " -Wno-error=sfinae-incomplete";
    });
  })
]
