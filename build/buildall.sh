#!/usr/bin/env bash

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
for file in `ls -1 $root_dir/dist/*`; do
  program=`basename $file | sed -e 's/.lua$//g'`
  $root_dir/build/build.sh $program
done  
