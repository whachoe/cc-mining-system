#!/usr/bin/env bash
# Builds dist/<name>.lua and uploads it to Pastebin under the account
# configured in .env.local, then prints the `pastebin get` command to run
# on the turtle.
#
# Requires in .env.local: PASTEBIN_USER, PASTEBIN_PASSWORD, and
# PASTEBIN_API_DEV_KEY (a dev key from https://pastebin.com/api, tied to
# your Pastebin account -- separate from your login password).
set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: $0 <program-name>" >&2
  exit 1
fi

name="$1"
root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ -f "$root_dir/.env.local" ]; then
  set -a
  # shellcheck source=/dev/null
  source "$root_dir/.env.local"
  set +a
elif [ -f "$root_dir/.env" ]; then
  set -a
  # shellcheck source=/dev/null
  source "$root_dir/.env"
  set +a
fi

: "${PASTEBIN_USER:?PASTEBIN_USER not set in .env.local}"
: "${PASTEBIN_PASSWORD:?PASTEBIN_PASSWORD not set in .env.local}"
: "${PASTEBIN_API_DEV_KEY:?PASTEBIN_API_DEV_KEY not set in .env.local (get one at pastebin.com/api)}"

bash "$root_dir/build/build.sh" "$name"
paste_file="$root_dir/dist/$name.lua"

echo "Uploading $paste_file..."
paste_url=$(curl -sS \
  --data-urlencode "api_dev_key=$PASTEBIN_API_DEV_KEY" \
  --data-urlencode "api_option=paste" \
  --data-urlencode "api_paste_private=1" \
  --data-urlencode "api_paste_name=$name.lua" \
  --data-urlencode "api_paste_code@$paste_file" \
  https://pastebin.com/api/api_post.php)

if [[ "$paste_url" != http* ]]; then
  echo "Pastebin upload failed: $paste_url" >&2
  exit 1
fi

paste_code="${paste_url##*/}"
echo
echo "Uploaded: $paste_url"
echo "On the turtle, run:"
echo "  pastebin get $paste_code $name"
