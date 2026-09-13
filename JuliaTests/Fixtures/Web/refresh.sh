#!/usr/bin/env bash
#
# Re-captures the Web fixtures listed in urls.txt.
#
# Usage:  JuliaTests/Fixtures/Web/refresh.sh [fixture-name ...]
#
# With no arguments, refreshes every entry. With names, only those.
#
# Saved pages are large and mostly irrelevant markup, but they are the input
# the parser actually has to cope with, so they are kept verbatim rather than
# trimmed by hand — trimming risks removing the very thing that broke.
set -euo pipefail

cd "$(dirname "$0")"

wanted=("$@")

want() {
  [[ ${#wanted[@]} -eq 0 ]] && return 0
  local name="$1"
  for w in "${wanted[@]}"; do [[ "$w" == "$name" ]] && return 0; done
  return 1
}

count=0
while read -r name url; do
  # Skip comments and blanks.
  [[ -z "${name:-}" || "${name:0:1}" == "#" ]] && continue
  [[ -z "${url:-}" ]] && { echo "skipping $name: no URL recorded"; continue; }
  want "$name" || continue

  echo "fetching $name <- $url"
  # A browser user agent: several recipe sites serve a stub to unknown clients,
  # and a stub has no JSON-LD, which would look like a parser regression.
  if curl -sSL --fail --max-time 30 \
      -A 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15' \
      -o "$name.html" "$url"; then
    if grep -qi 'application/ld+json' "$name.html"; then
      echo "  saved $name.html ($(wc -c < "$name.html" | tr -d ' ') bytes)"
      count=$((count + 1))
    else
      echo "  WARNING: $name.html has no JSON-LD block — check the page, or move it out of Web/"
    fi
  else
    echo "  FAILED: left the previous $name.html in place"
  fi
done < urls.txt

echo "refreshed $count fixture(s)"
