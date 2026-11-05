#!/bin/sh
# Shared by the version gate and bump tool. Keep the format compatible with
# UpdateVersion: canonical major.minor.patch+build and signed 64-bit parts.
valid_version() {
  printf '%s\n' "$1" | awk -F '[.+]' '
    NF != 4 { exit 1 }
    {
      for (i = 1; i <= 4; i++) {
        if ($i !~ /^(0|[1-9][0-9]*)$/) exit 1
      }
      for (i = 1; i <= 3; i++) {
        if (length($i) > 19 ||
            (length($i) == 19 && "x" $i > "x9223372036854775807")) exit 1
      }
      if (length($4) > 10 || $4 < 1 || $4 > 2100000000) exit 1
    }
  '
}
