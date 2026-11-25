#!/usr/bin/env bash
# Unit and fixture tests. No root, no network, no compiler needed.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(dirname "$HERE")"
# shellcheck disable=SC1091
source "$ROOT/bin/fprint-elan-0c4c"   # main is not run when sourced
set +e +u
trap - EXIT

pass=0; failn=0
check() { # check <description> <expected> <actual>
  if [[ "$2" == "$3" ]]; then pass=$((pass+1)); printf 'ok   %s\n' "$1"
  else failn=$((failn+1)); printf 'FAIL %s\n  expected: %s\n  actual:   %s\n' "$1" "$2" "$3"; fi
}

# --- version normalisation -------------------------------------------------
check "debian epoch+tod"   "1.94.7"   "$(normalize_version '1:1.94.7+tod1-0ubuntu1')"
check "fedora"             "1.94.100" "$(normalize_version '1.94.100')"
check "arch"               "1.94.9"   "$(normalize_version '1.94.9-1')"
check "tilde suffix"       "1.94.5"   "$(normalize_version '1.94.5~rc1')"

# --- pinned data -----------------------------------------------------------
check "pinned commit lookup" "80a4b5ec612892c5c056c48dddaa561452cf37ec" "$(pinned_commit 1.94.100)"
check "unknown version has no pin" "" "$(pinned_commit 9.9.9)"
check "status lookup" "hardware-tested" "$(version_status 1.94.100)"
check "comment lines are never versions" "" "$(pinned_commit '#')"

# --- vendored files match their pinned checksums ---------------------------
( cd "$ROOT" && sha256sum --quiet -c data/SHA256SUMS ) 2>/dev/null
check "driver checksums verify" "0" "$?"

# --- registration on both layouts, and a refusal on an unknown one ----------
reg() { # reg <fixture> -> prints "ok" or "fail"
  local d; d="$(mktemp -d)"; cp -r "$ROOT/tests/fixtures/$1/." "$d/"
  ( wire_driver "$d" ) >/dev/null 2>&1 && grep -q elanmoc_0c4c "$d/meson.build" \
    && grep -q elanmoc_0c4c "$d/libfprint/meson.build" \
    && [[ -f "$d/libfprint/drivers/elanmoc_0c4c/elanmoc_0c4c.c" ]] && echo ok || echo fail
  rm -rf "$d"
}
check "wire old layout (<=1.94.10)"  "ok"   "$(reg old)"
check "wire new layout (1.94.100)"   "ok"   "$(reg new)"
check "refuse unknown layout"        "fail" "$(reg unknown)"

# old layout registers in both driver lists
d="$(mktemp -d)"; cp -r "$ROOT/tests/fixtures/old/." "$d/"; ( wire_driver "$d" ) >/dev/null 2>&1
check "old layout: driver listed twice in meson.build" "2" "$(grep -c "'elanmoc_0c4c'," "$d/meson.build")"
rm -rf "$d"

# tests/examples are dropped when unneeded, kept when the library includes a header generated there
d="$(mktemp -d)"; cp -r "$ROOT/tests/fixtures/old/." "$d/"; ( wire_driver "$d" ) >/dev/null 2>&1
check "tests/examples subdirs removed when unneeded" "0" "$(grep -cE "subdir\('(tests|examples)'\)" "$d/meson.build")"
rm -rf "$d"
d="$(mktemp -d)"; cp -r "$ROOT/tests/fixtures/new/." "$d/"; ( wire_driver "$d" ) >/dev/null 2>&1
check "tests/examples subdirs kept when the library needs them" "2" "$(grep -cE "subdir\('(tests|examples)'\)" "$d/meson.build")"
rm -rf "$d"

# --- safety patch is really applied to the copied driver -------------------
d="$(mktemp -d)"; cp -r "$ROOT/tests/fixtures/new/." "$d/"; ( wire_driver "$d" ) >/dev/null 2>&1
grep -q 'not enrolled by libfprint' "$d/libfprint/drivers/elanmoc_0c4c/elanmoc_0c4c.c"
check "safety patch applied (delete guard)" "0" "$?"
grep -q 'FP_ELAN_0C4C_ALLOW_CLEAR' "$d/libfprint/drivers/elanmoc_0c4c/elanmoc_0c4c.c"
check "safety patch applied (clear guard)" "0" "$?"
rm -rf "$d"

# --- install refuses dangerous prefixes -------------------------------------
for bad in / /usr /usr/local /etc /home/me /opt relative/path "/opt/x y" "/opt/../usr"; do
  (validate_prefix "$bad") >/dev/null 2>&1; rc=$?
  check "prefix '$bad' refused" "1" "$rc"
done
(validate_prefix /opt/fprint-elan-0c4c) >/dev/null 2>&1
check "prefix /opt/fprint-elan-0c4c accepted" "0" "$?"

printf '\n%d passed, %d failed\n' "$pass" "$failn"
[[ $failn -eq 0 ]]
