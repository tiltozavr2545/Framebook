#!/bin/sh
# Exercise version tools in a disposable fixture, never in the real checkout.
set -eu
scripts=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
fixture=$(mktemp -d)
trap 'rm -rf "$fixture"' EXIT HUP INT TERM
mkdir -p "$fixture/app" "$fixture/bin"
cat > "$fixture/bin/git" <<'EOF'
#!/bin/sh
printf 'version: %s\n' "$TEST_BASE_VERSION"
EOF
chmod +x "$fixture/bin/git"
PATH="$fixture/bin:$PATH"
export PATH
cd "$fixture"

check_bump() {
  before=$1 kind=$2 expected=$3
  printf 'version: %s\n' "$before" > app/pubspec.yaml
  if sh "$scripts/bump-version.sh" "$kind" > result.log 2>&1; then
    [ -n "$expected" ] || { cat result.log; echo "Unexpected bump: $before"; exit 1; }
    actual=$(awk '{print $2}' app/pubspec.yaml)
    [ "$actual" = "$expected" ] || { echo "Expected $expected, got $actual"; exit 1; }
  else
    [ -z "$expected" ] || { cat result.log; exit 1; }
    [ "$(cat app/pubspec.yaml)" = "version: $before" ] || { echo 'Failure modified pubspec'; exit 1; }
  fi
}

check_bump '1.2.3+4' build '1.2.3+5'
check_bump '1.2.3+4' patch '1.2.4+5'
check_bump '1.2.3+4' minor '1.3.0+5'
check_bump '1.2.3+4' major '2.0.0+5'
check_bump '1.2.999+4' patch '1.2.1000+5'
check_bump '1.2.9223372036854775807+4' patch ''
check_bump '9223372036854775808.2.3+4' build ''
for invalid in '1.2+4' '1.2.3.4+4' '1..3+4' '1.2.3+' '1.2.3+abc' '1.2.3+0' '1.2.3+08' '01.2.3+4' '1.2.3+2100000000' '1.2.3+999999999999999999999'; do
  check_bump "$invalid" build ''
done

check_verify() {
  TEST_BASE_VERSION=$1
  export TEST_BASE_VERSION
  printf 'version: %s\n' "$2" > app/pubspec.yaml
  if BASE_REF=fixture sh "$scripts/verify-version.sh" > result.log 2>&1; then
    [ "$3" = pass ] || { cat result.log; echo "Unexpected acceptance: $1 -> $2"; exit 1; }
  else
    [ "$3" = fail ] || { cat result.log; exit 1; }
  fi
}
check_verify '1.2.3+4' '1.2.3+5' pass
check_verify '1.2.3+4' '1.3.0+5' pass
check_verify '1.2.3+4' '1.2.2+5' fail
check_verify '1.2.3+4' '1.2.3+4' fail
check_verify '1.2.3+4' '1.2.3+' fail
check_verify '1.2.3+4' '1.2.3+999999999999999999999' fail
check_verify '1.2.3+4' '1.2.3+05' fail
check_verify '1.2.3+4' '01.2.3+5' fail
check_verify '1.2.3+0' '1.2.3+5' fail
check_verify '1.2.9007199254740993+4' '1.2.9007199254740992+5' fail
check_verify '1.2.9007199254740992+4' '1.2.9007199254740993+5' pass
printf '%s\n' 'Version script tests passed.'
