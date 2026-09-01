---
title: Test complet — Extension “Document” Test complet — Extension “Document” Test complet — Extension “Document” Test complet — Extension “Document” Test complet — Extension “Document”
subtitle: Vérification de tous les éléments de mise en forme
author: Chris Mann
date: 7 juin 2026
lang: fr
---

DOC HEADER  
DOC HEADER  
DOC HEADER  
DOC HEADER  
DOC HEADER

---

# Test complet — Extension “Document” Test complet — Extension “Document” Test complet — Extension “Document” Test complet — Extension “Document” Test complet — Extension “Document”

*Chris Mann*

*7 juin 2026*

## Table des matières

# Niveau 1 — Introduction

L’extension **Document** fournit un gabarit de mise en page pour des documents formels. Elle partage les filtres et la feuille de style de l’extension *Lettre*, mais sans la structure épistolaire.

Logo intégré en tête de document :

<figure>
<img src="logo-lesgrandsvoisins-900-150-white.png" alt="Logo Les Grands Voisins" />
<figcaption aria-hidden="true">Logo Les Grands Voisins</figcaption>
</figure>

Du texte en **gras**, en *italique*, en ***gras italique*** et du `code inline`. Un lien vers [Quarto](https://quarto.org) et une note de bas de page[1].

> Un bloc de citation pour illustrer la mise en forme d’un extrait ou d’une référence dans un document formel.

# Niveau 1 — Listes

Liste non ordonnée avec sous-éléments :

- Format HTML — rendu dans le navigateur
  - Thème personnalisé via CSS
  - Mise en page à colonnes
- Format PDF — rendu via LaTeX
  - Classe `quarto-lettre.cls`
  - Support A4 et lettre US
- Format Typst — rendu natif
- Format DOCX — compatible Microsoft Word
- Format Markdown — sortie texte enrichi

Liste ordonnée :

1.  Installer Quarto 1.9 ou supérieur
2.  Copier le dossier `_extensions/` dans le projet
3.  Créer un fichier `.qmd` avec les métadonnées requises
4.  Lancer `quarto render fichier.qmd`

## Niveau 2 — Tableaux

Tableau des formats supportés :

| Extension    | HTML | PDF | Typst | DOCX | ODT | Markdown | Texte |
|:-------------|:----:|:---:|:-----:|:----:|:---:|:--------:|:-----:|
| lettre       |  ✓   |  ✓  |   ✓   |  ✓   |  ✓  |    ✓     |   ✓   |
| compte-rendu |  ✓   |  ✓  |   ✓   |  —   |  —  |    ✓     |   ✓   |
| document     |  ✓   |  ✓  |   ✓   |  ✓   |  —  |    ✓     |   ✓   |

Image à largeur réduite insérée dans le flux du document :

<figure>
<img src="logo-lesgrandsvoisins-900-150-white.png" style="width:50.0%" alt="Logo 50 %" />
<figcaption aria-hidden="true">Logo 50 %</figcaption>
</figure>

## Niveau 2 — Blocs de code

Configuration YAML minimale :

``` yaml
---
title: "Mon document"
author: "Prénom Nom"
date: today
lang: fr
format:
  document-pdf: default
  document-html: default
---
```

Commande de rendu :

``` bash
quarto render document.qmd
```

### Niveau 3 — Tableau de facturation

<table id="tbl-budget" width="100%">
<thead>
<tr>
<th style="text-align: left;">Poste</th>
<th style="text-align: right;">Coût unitaire</th>
<th style="text-align: right;">Quantité</th>
<th style="text-align: right;">Total</th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align: left;">Développement</td>
<td style="text-align: right;">500 €</td>
<td style="text-align: right;">10</td>
<td style="text-align: right;">5 000 €</td>
</tr>
<tr>
<td style="text-align: left;">Documentation</td>
<td style="text-align: right;">200 €</td>
<td style="text-align: right;">5</td>
<td style="text-align: right;">1 000 €</td>
</tr>
<tr>
<td style="text-align: left;">Tests</td>
<td style="text-align: right;">150 €</td>
<td style="text-align: right;">8</td>
<td style="text-align: right;">1 200 €</td>
</tr>
<tr>
<td colspan="3" style="text-align: right;" data-border-top="solid 1px">
<strong>Total</strong></td>
<td style="text-align: right;"><strong>7 200 €</strong></td>
</tr>
</tbody>
</table>

Budget prévisionnel

### Niveau 3 — Image avec légende

<figure>
<img src="logo-lesgrandsvoisins-900-150-white.png" alt="Logo Les Grands Voisins — format original" />
<figcaption aria-hidden="true">Logo Les Grands Voisins — format original</figcaption>
</figure>

#### Niveau 4 — Filtres Lua

Les filtres Lua permettent d’adapter le rendu selon le format de sortie cible. Exemple de filtre :

``` lua
function Image(el)
  if FORMAT == "latex" then
    el.attributes["width"] = "\\linewidth"
  end
  return el
end
```

#### Niveau 4 — Métadonnées YAML

Les métadonnées `title`, `subtitle`, `author` et `date` sont injectées dans le gabarit par Pandoc. La variable `lang` contrôle la localisation des éléments automatiques (date, bibliographie, etc.).

[1] L’extension requiert Quarto 1.9 ou supérieur.

---

DOC FOOTER  
DOC FOOTER  
DOC FOOTER  
DOC FOOTER  
DOC FOOTER  
DOC FOOTER  
DOC FOOTER
