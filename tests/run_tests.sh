#!/usr/bin/env bash
# Runs every tests/test_*.lua under lua5.1 against the mocked CC:Tweaked
# API. Exits non-zero if any test file fails.
set -uo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root_dir"

lua_bin="${LUA_BIN:-lua5.1}"
failures=0

for test_file in tests/test_*.lua; do
  echo "== $test_file =="
  if ! "$lua_bin" "$test_file"; then
    failures=$((failures + 1))
  fi
  echo
done

if [ "$failures" -ne 0 ]; then
  echo "$failures test file(s) failed"
  exit 1
fi

echo "All tests passed"
