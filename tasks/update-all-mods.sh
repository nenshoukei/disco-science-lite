#!/bin/bash
# Updates scripts/prototype/mods/_all.lua to require all *.lua files in the same directory.
# base and space-age are loaded first, then the rest in alphabetical order.

set -euo pipefail

MODS_DIR="$(dirname "$0")/../scripts/prototype/mods"
OUTPUT="$MODS_DIR/_all.lua"

# Collect all .lua files except _all.lua
files=()
while IFS= read -r -d '' f; do
  name="$(basename "$f" .lua)"
  files+=("$name")
done < <(find "$MODS_DIR" -maxdepth 1 -name "*.lua" ! -name "_all.lua" -print0 | sort -z)

# Priority mods loaded first, in order
priority=(base space-age)

# Remaining mods: files not in priority, sorted alphabetically
rest=()
for name in "${files[@]}"; do
  skip=false
  for p in "${priority[@]}"; do
    if [[ "$name" == "$p" ]]; then
      skip=true
      break
    fi
  done
  if [[ "$skip" == false ]]; then
    rest+=("$name")
  fi
done

old_hash="$(sha1sum "$OUTPUT")"

# Write output
{
  echo "return {"
  for name in "${priority[@]}"; do
    echo "  require(\"scripts.prototype.mods.$name\"),"
  done
  for name in "${rest[@]}"; do
    echo "  require(\"scripts.prototype.mods.$name\"),"
  done
  echo "}"
} > "$OUTPUT"

new_hash="$(sha1sum "$OUTPUT")"

if [ "$old_hash" != "$new_hash" ]; then
  echo "Updated $OUTPUT"
fi
