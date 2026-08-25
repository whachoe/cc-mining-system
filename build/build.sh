#!/usr/bin/env bash
# Concatenates src/lib/*.lua (in numeric-prefix order) with one
# src/programs/<name>.lua into a single dist/<name>.lua, since CC:Tweaked
# turtles run a single flat file with no module/require system.
set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: $0 <program-name>" >&2
  exit 1
fi

name="$1"
root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
lib_dir="$root_dir/src/lib"
program_file="$root_dir/src/programs/$name.lua"
dist_dir="$root_dir/dist"

if [ ! -f "$program_file" ]; then
  echo "No such program: $program_file" >&2
  exit 1
fi

mkdir -p "$dist_dir"
out_file="$dist_dir/$name.lua"

{
  for lib_file in "$lib_dir"/*.lua; do
    echo "-- ---- $(basename "$lib_file") ----"
    cat "$lib_file"
    echo
  done
  echo "-- ---- $name.lua ----"
  cat "$program_file"
} > "$out_file"

echo "Built $out_file"
