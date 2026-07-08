qlettre-init() {
  mkdir -p "$1" && cd "$1" || return
  quarto add ~/dev/quarto-lettre --no-prompt
  cp ~/dev/quarto-lettre/_quarto.yml .
  cp ~/dev/quarto-lettre/template.qmd "./$(basename "$1").qmd"
}
