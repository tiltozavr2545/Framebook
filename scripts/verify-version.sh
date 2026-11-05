#!/bin/sh
set -eu
. "$(dirname -- "$0")/version-format.sh"

base_ref=${BASE_REF:?BASE_REF must point to the PR base commit}

read_version() {
	awk '/^version:[[:space:]]/ { print $2; exit }' "$@"
}

base_version=$(git show "$base_ref:app/pubspec.yaml" | awk '/^version:[[:space:]]/ { print $2; exit }')
current_version=$(read_version app/pubspec.yaml)

for version in "$base_version" "$current_version"; do
	if ! valid_version "$version"; then
		echo "Invalid version: expected canonical major.minor.patch+build with a positive versionCode up to 2100000000, got '$version'" >&2
		exit 1
	fi
done

base_name=${base_version%+*}
current_name=${current_version%+*}
base_code=${base_version##*+}
current_code=${current_version##*+}

# Marketing versions may stay the same, but must not go backwards.
# Compare decimal strings exactly, including components beyond float precision.
name_status=0
printf '%s\n' "$base_name" "$current_name" | awk -F. '
function compare(a, b) {
  if (length(a) != length(b)) return length(a) < length(b) ? -1 : 1
  if ("x" a == "x" b) return 0
  return "x" a < "x" b ? -1 : 1
}
NR == 1 { base = $0; next }
NR == 2 {
  split(base, b); split($0, c)
  for (i = 1; i <= 3; i++) {
    result = compare(c[i], b[i])
    if (result < 0) exit 1
    if (result > 0) exit 0
  }
}
' || name_status=$?

case "$name_status" in
	0) ;;
	1)
		echo "versionName must not decrease: $base_name -> $current_name" >&2
		exit 1
		;;
	*)
		echo "versionName must be major.minor.patch, for example 0.3.1: '$base_name' -> '$current_name'" >&2
		exit 1
		;;
esac

if [ "$current_code" -le "$base_code" ]; then
	echo "PR version bump required: versionCode must increase from $base_code to $current_code" >&2
	exit 1
fi

printf '%s\n' "Version check passed: $base_version -> $current_version"
