#!/bin/sh
set -eu
. "$(dirname -- "$0")/version-format.sh"

pubspec="app/pubspec.yaml"

usage() {
	cat >&2 <<'EOF'
Usage: scripts/bump-version.sh <build|patch|minor|major>

  build   Keep versionName the same, bump only versionCode (the build
          number). Valid on its own for a Play Store / App Store release —
          neither store requires versionName to change between uploads.
  patch   Bump versionName's patch component (0.18.8 -> 0.18.9) and
          versionCode.
  minor   Bump versionName's minor component, reset patch to 0
          (0.18.8 -> 0.19.0), and bump versionCode.
  major   Bump versionName's major component, reset minor and patch to 0
          (0.18.8 -> 1.0.0), and bump versionCode.

versionCode always increases by 1 — Play Store requires every upload to
carry a strictly higher versionCode than any before it, in any track.
EOF
	exit 1
}

[ $# -eq 1 ] || usage

case "$1" in
	build | patch | minor | major) ;;
	*) usage ;;
esac
kind="$1"

[ -f "$pubspec" ] || {
	echo "Error: $pubspec not found — run this from the repository root." >&2
	exit 1
}

current_version=$(awk '/^version:[[:space:]]/ { print $2; exit }' "$pubspec")
[ -n "$current_version" ] || {
	echo "Error: could not read 'version:' from $pubspec" >&2
	exit 1
}

if ! valid_version "$current_version"; then
	echo "Error: expected canonical major.minor.patch+build with a positive versionCode up to 2100000000 (found: $current_version)" >&2
	exit 1
fi

current_name=${current_version%+*}
current_code=${current_version##*+}

major=$(printf '%s' "$current_name" | cut -d. -f1)
minor=$(printf '%s' "$current_name" | cut -d. -f2)
patch=$(printf '%s' "$current_name" | cut -d. -f3)

case "$kind" in
	build) ;;
	patch | minor | major)
		case "$kind" in
			patch) part=$patch ;;
			minor) part=$minor ;;
			major) part=$major ;;
		esac
		if [ "$part" = 9223372036854775807 ]; then
			echo "Error: version component would overflow" >&2
			exit 1
		fi
		case "$kind" in
			patch) patch=$((patch + 1)) ;;
			minor) minor=$((minor + 1)); patch=0 ;;
			major) major=$((major + 1)); minor=0; patch=0 ;;
		esac
		;;
esac

if [ "$current_code" -ge 2100000000 ]; then
	echo "Error: versionCode would exceed 2100000000" >&2
	exit 1
fi

new_name="$major.$minor.$patch"
new_code=$((current_code + 1))
new_version="$new_name+$new_code"

# BSD sed (macOS) needs -i '' ; GNU sed needs -i without an argument. Try BSD
# form first and fall back, rather than branching on `uname` — the failure
# mode (a literal `''` argument file) is exactly what -i '' avoids, and GNU
# sed's -i accepts a following script argument as the suffix if given one, so
# guessing wrong is not silently harmless.
if sed --version >/dev/null 2>&1; then
	sed -i "s/^version: $current_version\$/version: $new_version/" "$pubspec"
else
	sed -i '' "s/^version: $current_version\$/version: $new_version/" "$pubspec"
fi

printf '%s\n' "Bumped $pubspec: $current_version -> $new_version"
