#! /bin/bash

CPUFEATURES="$(wget -qO- "https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/plain/arch/x86/include/asm/cpufeatures.h")"
grep "^flags" /proc/cpuinfo |
  uniq |
  sed 's/^.*: //' |
  tr ' ' '\n' |
  while read -r line; do
    echo -n "${line}: "
    echo "$CPUFEATURES" |
      grep "FEATURE_${line^^}" |
      sed 's|.*) /\* ||' |
      sed 's| \*/$||'
  done
