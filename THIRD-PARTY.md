# Composants tiers

Ce dépôt inclut les composants tiers suivants. Ils restent la propriété de
leurs auteurs respectifs et sont distribués sous leur licence d'origine.

## `droit-fr` (classe et styles biblatex)

- Fichiers : `_extensions/droit-fr/latex/droit-fr-patched.bbx`,
  `_extensions/droit-fr/latex/droit-fr-patched.cbx`
- Origine : paquet CTAN `droit-fr` (<https://ctan.org/pkg/droit-fr>)
- Licence : LaTeX Project Public License (LPPL)
- Modification : l'amont (2016) ne compile plus avec biblatex >= 3.20
  (formats de noms utilisant les anciens arguments `#1`–`#8`). Une copie
  renommée `droit-fr-patched`, avec ces deux formats portés, est embarquée
  comme la LPPL l'exige.

## Style CSL

- Fichier : `_extensions/base/resources/biblio.csl`
- Auteur : Chris Mann
- Licence : MIT (voir `LICENSE`).

## Polices

Les polices éventuellement référencées par une marque (`brand.yml`) ne sont
pas redistribuées ici : elles sont chargées depuis Google Fonts (HTML) ou
utilisées localement via `fontspec` (PDF).
