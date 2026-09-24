#!/usr/bin/env bash
# Keeps the `version:` line of the lockstep extensions (base, document, lettre,
# compte-rendu, quarto) identical. site, *-web, latex-environment (upstream's
# number) and gdvoisins have their own numbering and are left alone.
#
#   bump-version.sh           check that all five agree (exit 1 if not)
#   bump-version.sh 0.2.12    set all five to 0.2.12 (a leading "v" is accepted)
#
# Run from anywhere; paths are resolved relative to this script.
set -euo pipefail

ext_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
extensions=(base document lettre compte-rendu quarto)

current() { sed -n 's/^version:[[:space:]]*//p' "$ext_dir/$1/_extension.yml"; }

if [[ $# -eq 0 ]]; then
  status=0
  for e in "${extensions[@]}"; do
    printf '%-12s %s\n' "$e" "$(current "$e")"
  done
  [[ $(for e in "${extensions[@]}"; do current "$e"; done | sort -u | wc -l) -eq 1 ]] \
    || { echo "Versions differ" >&2; status=1; }
  exit "$status"
fi

new="${1#v}"
[[ $new =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "Not a X.Y.Z version: $1" >&2; exit 2; }

for e in "${extensions[@]}"; do
  sed -i -E "s/^(version:[[:space:]]*).*/\1$new/" "$ext_dir/$e/_extension.yml"
done
echo "Set ${extensions[*]} to $new. Next: update CHANGELOG.md, commit, git tag v$new"
