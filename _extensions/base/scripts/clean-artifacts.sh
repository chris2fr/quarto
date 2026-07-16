#!/usr/bin/env bash
# Post-render cleanup: removes LaTeX/Typst intermediate files and support
# directories that Quarto leaves next to the source .qmd files (format
# resources such as quarto-lettre.cls are never cleaned up by Quarto itself).
# _parts/ is excluded: it's user-owned content (header/footer/body overrides,
# and an optional custom.cls), not a render artifact, so it must survive
# the *.tex/*.cls sweep below even though those extensions match.
set -euo pipefail

prune=(-path './_extensions' -o -path './_output' -o -path './.quarto' -o -path './.git' -o -path './_parts')

find . \( "${prune[@]}" \) -prune -o \
  -type f \( -name '*.tex' -o -name '*.cls' -o -name '*.typ' \) -not -name 'custom.cls' -print0 | xargs -0 -r rm -f

find . \( "${prune[@]}" \) -prune -o \
  -type d -name '*_files' -print0 | xargs -0 -r rm -rf
