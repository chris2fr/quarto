# Quarto Lettre — Extension family

Three Quarto format extensions for composing formal French documents from a single `.qmd` source file:

| Extension | Purpose | Formats |
|---|---|---|
| `lettre` | Formal letter | HTML, PDF, Typst, DOCX, ODT, Markdown, plain text |
| `compte-rendu` | Meeting minutes | HTML, PDF, Typst, Markdown, plain text |
| `document` | General document | HTML, PDF, Typst, Markdown, plain text |

All three share a common `_extensions/base/` resource directory (Lua filters, CSL style, templates).

---

## Quickstarts

L'extension est requise :

```bash
quarto add chris2fr/quarto
```

Vous pouvez utiliser un template :

```
quarto use template chris2fr/quarto/document
quarto use template chris2fr/quarto/lettre
quarto use template chris2fr/quarto/compte-rendu
quarto use template chris2fr/quarto/gdvoisins/document
quarto use template chris2fr/quarto/gdvoisins/lettre
quarto use template chris2fr/quarto/gdvoisins/compte-rendu
```

Vous pouvez utiliser un brand :


```
quarto use brand chris2fr/quarto
quarto use brand chris2fr/quarto/gdvoisins
```

Types de documents:

- document
- lettre
- compte-rendu

Formats de sorti

- -pdf
- -html
- -typst
- -plain
- -md
- -odt
- -docx

Brands :

- quarto use brand chris2fr/quarto
- quarto use brand chris2fr/quarto/gdvoisins

Templates :

- quarto use template chris2fr/quarto
- quarto use template chris2fr/quarto/document
- quarto use template chris2fr/quarto/lettre
- quarto use template chris2fr/quarto/compte-rendu
- quarto use template chris2fr/quarto/gdvoisins/document
- quarto use template chris2fr/quarto/gdvoisins/lettre
- quarto use template chris2fr/quarto/gdvoisins/compte-rendu

---

## Requirements

- Quarto ≥ 1.9.0
- A LaTeX distribution — for `*-pdf` formats
- Typst — for `*-typst` formats (bundled with Quarto ≥ 1.4)

---

## lettre

### Metadata

```yaml
---
title: Objet de la lettre
author: Prénom Nom
ref: ref-2026-01-01
lang: fr
place: Paris
date: today
format:
  lettre-html: default
  lettre-pdf: default
  lettre-typst: default
  lettre-docx: default
  lettre-odt: default
  lettre-md: default
  lettre-plain: default
---
```

`title`, `author`, `lang`, `date`, `place`, and `ref` are all required — rendering stops with an error listing whichever are missing.

### Divs

| Div | Role | If missing |
|---|---|---|
| `::: header1` | Page header — printed on the first page only | falls back to a part (see below), or omitted |
| `::: from` | Sender's address | falls back to a part |
| `::: date` | Place and date | falls back to a part |
| `::: to` | Recipient's address | falls back to a part |
| `::: subject` | Subject line | falls back to a part |
| `::: ref` | Reference number | falls back to a part, or omitted |
| `::: opening` | Salutation | falls back to a part |
| `::: body` | Body of the letter | any content in the document that isn't inside one of these divs is concatenated into the body automatically — see below |
| `::: closing` | Closing formula | falls back to a part |
| `::: signature` | Sender's name and title | falls back to a part |
| `::: ps` | Postscript, printed after the signature | falls back to a part, or omitted |
| `::: annexes` | List of enclosures, printed after the postscript | falls back to a part, or omitted |
| `::: footer` | Page footer — printed on every page | falls back to a part, or omitted |

Leave `::: header1` or `::: footer` **empty** (`::: header1\n:::`) to suppress the header/footer area outright — that's different from omitting the div entirely, which triggers the part fallback below.

YAML metadata values are reusable anywhere in the document via `{{< meta key >}}`.

#### Body without a `::: body :::` wrapper

`::: body` doesn't have to be written explicitly. Any top-level content that isn't inside a recognized div — paragraphs, headings, tables, images, custom divs — is concatenated, in document order, into the body automatically. This means a minimal letter can be just:

```markdown
---
title: Objet de la lettre
author: Prénom Nom
lang: fr
date: today
format:
  lettre-html: default
---

Le corps de la lettre, sans aucun div.
```

Everything else (`from`, `date`, `to`, `subject`, `opening`, `closing`, `signature`, `ps`, `annexes`, `header1`, `footer`) is filled in from parts (see below). Mixing is fine: write the divs you care about, and let the rest fall back.

#### Logo, link and description in the header

`::: header1` (and `::: footer`) accept a linked, described image — the description doubles as the image's alt text:

```markdown
::: header1
[![Organisation — courte description](logo.png)](https://example.org)
:::
```

The image is capped to a sensible header height and centered in every format (HTML, Typst, PDF/LaTeX, docx, odt). If the project has a [brand.yml](https://quarto.org/docs/authoring/brand.html), the logo can come from there instead via the `{{< brand logo <size> >}}` shortcode (`small`, `medium`, or `large`), optionally wrapped in a link the same way:

```markdown
::: header1
[{{< brand logo medium >}}](https://example.org)
:::
```

#### `_parts/` — overriding or omitting a section

Any div listed as "falls back to a part" above can be left out of the document entirely. When it is, its content is resolved in priority order:

1. `./_parts/<div>.qmd` — next to the `.qmd` being rendered (overrides just that document)
2. `<project root>/_parts/<div>.qmd` — the directory holding `_quarto.yml` (overrides every letter in the project)
3. the extension's own bundled default (`_extensions/base/parts/<div>.qmd`)

The first one found wins, so a project- or document-level `_parts/<div>.qmd` always takes precedence over the extension's default. Part files are plain Markdown and support `{{< meta key >}}` and `{{< brand logo <size> >}}` shortcodes.

`::: header1` / `::: footer` and their `_parts/header1.qmd` / `_parts/footer.qmd` fallback work the same way in `compte-rendu` and `document` — a single `_parts/header1.qmd` at the project root gives every letter, meeting minutes, and document in the project the same letterhead and footer. The rest of the fallback vocabulary (`from`, `date`, `to`, `subject`, `ref`, `opening`, `closing`, `signature`, `ps`, `annexes`) is specific to `lettre`.

Since `quarto add` has no post-install hook to scaffold `_parts/` automatically, the extension does the next best thing: the first time a document is rendered in a project (or standalone file) that has no `_parts/` yet, one is created — at the project root if there's a `_quarto.yml`, next to the document otherwise — populated with an editable copy of every fallback-eligible part for that extension (just `header1.qmd`/`footer.qmd` for `compte-rendu`/`document`; the full set for `lettre`). An existing `_parts/` (even an empty one, or one missing some files) is never touched again, so this only ever runs once and never overwrites customizations.

#### Filling a div straight from metadata

Any div listed as "falls back to a part" above — plus, in `compte-rendu`, `participants`, `agenda`, `decisions`, `actions`, `next-meeting`, `approval` — can also be filled directly from the document's own YAML front matter, instead of writing a `::: div ::: ... :::` block or a `_parts/<div>.qmd` file. The metadata key is the div's class name prefixed per extension — `let-` for `lettre`, `meet-` for `compte-rendu`, `doc-` for `document` — e.g. `let-to`, `let-ps`, `meet-agenda`, `doc-footer`:

```yaml
---
title: Objet de la lettre
author: Prénom Nom
lang: fr
let-to: |
  Le développeur Quarto
  À qui de droit
let-ps: "P.-S. : Merci de répondre avant vendredi."
let-annexes:
  - Copie du dernier échange
  - Relevé d'informations
format:
  lettre-html: default
---
```

The prefix isn't just a naming convention: a bare `to:` or `from:` key collides with pandoc's own reserved `to`/`from` metadata (the writer/reader format) and silently breaks rendering ("Unknown output format ..."), so every div is namespaced the same way — prefix included — even where no such collision exists, for one predictable rule.

When set, the metadata value **always wins** — over an explicit `::: div ::: ... :::` written in the body, and over `_parts/`. Priority, most to least specific:

1. `let-<div>` / `meet-<div>` / `doc-<div>` metadata key
2. `::: <div> ::: ... :::` in the document body
3. `_parts/<div>.qmd` fallback chain (document, then project, then extension default) — `lettre`'s own divs and `header1`/`footer` only; `compte-rendu`'s divs have no `_parts/` fallback

The value can be a plain string, a multi-paragraph block scalar (`let-ps: |`), or a YAML list — rendered as a bullet list (`let-annexes: [...]`).

For a `compte-rendu` div with no `_parts/` fallback to place it by, a metadata-provided one that's entirely absent from the body is appended at the end, in this order: `participants`, `agenda`, `decisions`, `actions`, `next-meeting`, `approval` — ahead of `footer`. Write the div yourself (even empty, e.g. `::: agenda\n:::`) if you need it placed elsewhere.

#### `let-date`/`meet-date`/`doc-date` and `let-ref`/`meet-ref`/`doc-ref`

`date` and `ref` follow the same `let-`/`meet-`/`doc-` prefix convention, but override the plain top-level `date`/`ref` metadata value itself, rather than a div's content — `date` and `ref` are already required/optional top-level metadata (see each extension's Metadata section above), used well beyond `lettre`'s own `::: date :::`/`::: ref :::` divs: `compte-rendu` and `document` have no such divs at all, and instead read `date`/`ref` directly to build their own title block (meeting date, "Réf. : ..." line), in every format (HTML, PDF, Typst).

```yaml
---
title: Réunion du 31 juillet
author: Chris Mann
date: 2026-07-31
meet-date: "31 juillet 2026 (reporté depuis le 24)"
meet-ref: "CR-2026-042"
format:
  compte-rendu-html: default
---
```

Set `let-date`/`meet-date`/`doc-date` (resp. `-ref`) to override what's displayed, independent of the underlying `date`/`ref` value — the override is used verbatim (no automatic "Place, le" prefix or "réf." label), so include those yourself if you want them. Without an override, `lettre`'s own `::: date :::`/`::: ref :::` divs still behave exactly as described in the table above (falling back to a part, or an explicit div you wrote).

#### Referencing other metadata inside a `let-`/`meet-`/`doc-` value

`$title$`, `$author$`, `$lang$`, `$date$`, `$place$`, `$ref$` inside a `let-`/`meet-`/`doc-` value are replaced with that top-level metadata field:

```yaml
---
title: Réunion hebdomadaire
author: Chris Mann
date: 2026-07-31
place: Paris
meet-date: "Réunion du $date$ (reportée depuis le 24, $place$)"
let-annexes:
  - "Copie signée par $author$"
---
```

`$date$` comes out already formatted per `date-format`/`lang` (e.g. "31 juillet 2026"), since it's quarto's own resolved value, not a re-parsed raw string.

This uses pandoc's `$var$` template-variable syntax rather than `{{< meta ... >}}` (the syntax `_parts/*.qmd` files use) because quarto runs its own shortcode resolution over *every* metadata value — not just body content — before any extension filter sees them, and that pass silently empties out `{{< meta ... >}}` written inside a metadata value that references a sibling key, with no leftover text for us to recover it from. `$key$` avoids this: pandoc's markdown reader parses a bare `$key$` as inline math regardless of context, so quarto's shortcode pass never touches it, leaving something our filter can find and replace directly. One consequence: `$title$`/etc. are recognized *only* for these six keys — any other `$...$` (e.g. `$x^2$`, a price like `$100$`) is left as ordinary math, exactly as it would be anywhere else in the document.

---

## compte-rendu

### Metadata

```yaml
---
title: Réunion du projet
author: Prénom Nom
organization: Nom de l'organisation
date: today
place: Paris
lang: fr
format:
  compte-rendu-html: default
  compte-rendu-pdf: default
  compte-rendu-typst: default
  compte-rendu-md: default
  compte-rendu-plain: default
---
```

### Divs

| Div | Role |
|---|---|
| `::: header1` | Page header — printed on the first page only |
| `::: participants` | Attendees and apologies |
| `::: agenda` | Meeting agenda (ordered list) |
| `::: body` | Meeting notes — supports headings H1–H4, images, tables |
| `::: decisions` | Decisions taken |
| `::: actions` | Action items — typically a Markdown table |
| `::: next-meeting` | Date and details of the next meeting |
| `::: approval` | Approval statement |
| `::: footer` | Page footer — printed on every page |

`::: header1` and `::: footer` can be omitted — see "`_parts/` — overriding or omitting a section" under `lettre` above. The rest of this table has no `_parts/` fallback, but every div in it (`participants`, `agenda`, `decisions`, `actions`, `next-meeting`, `approval`, plus `header1`/`footer`) can be filled from a `meet-<div>` metadata key instead — see "Filling a div straight from metadata" under `lettre` above; a missing `::: participants` or `::: body` with no `meet-participants` metadata either is still an error.

---

## document

### Metadata

```yaml
---
title: Titre du document
subtitle: Sous-titre
author: Prénom Nom
date: today
lang: fr
format:
  document-html: default
  document-pdf: default
  document-typst: default
  document-md: default
  document-plain: default
---
```

No special divs — use standard Markdown headings (H1–H4), paragraphs, tables, lists, and images directly in the document body. It does, however, support `::: header1` and `::: footer`, with the same `_parts/` fallback as `compte-rendu` above — omit them and the page header/footer come from `_parts/header1.qmd` / `_parts/footer.qmd` if present, or from a `doc-header1` / `doc-footer` metadata key (see "Filling a div straight from metadata" under `lettre` above), which takes priority over both.

### Side-by-side columns (PDF only)

`document` supports `{{< mp-begin >}}` / `{{< mp-next >}}` / `{{< mp-end >}}` shortcodes for laying out a row of columns side by side — built on the third-party `latex-environment` extension. `{{< mp-begin >}}` opens the first column, `{{< mp-next >}}` closes the current one, inserts a gap, and opens the next one, and `{{< mp-end >}}` closes the last one:

```markdown
{{< mp-begin >}}
**Left column**\
some text here
{{< mp-next >}}
**Right column**\
some other text
{{< mp-end >}}
```

Everything between `{{< mp-begin >}}` and `{{< mp-end >}}` must stay in one continuous paragraph — no blank lines. A blank line (or any other block-level content, like a fenced div) forces a paragraph break, which stacks the columns vertically instead of placing them side by side, since LaTeX only keeps boxes on the same line within a single paragraph.

Each shortcode takes an optional `width` — a bare fraction of the text width (`width=0.3`) or an equivalent percentage (`width=30%`) — for that one column; with no `width`, columns default to splitting the row evenly-ish (`0.48` each for a plain two-column row). For three or more columns, set `{{< mp-begin columns=N >}}` once and every `{{< mp-next >}}` in that row picks up a shared default of `0.95/N` automatically, instead of repeating `width=` on each call.

`{{< mp-begin border=true >}}` frames every column of the row in a thin box (plain `\fbox{}` — no extra package). `{{< mp-begin gutter=1em >}}` replaces the default flexible `\hfill` gap between columns with a fixed one (any LaTeX length: `1em`, `5mm`, ...) — useful alongside `border=true` so the boxes sit a consistent distance apart instead of being pushed to the row's outer edges. `{{< mp-begin vline=true >}}` draws a thin vertical rule in each gap instead — a bare `\vrule` automatically stretches to the height of the tallest column on that line, so it spans the row correctly with no manual height needed; combine with `gutter=` to center the rule in a fixed-width gap rather than the (still flexible) `\hfill` default. Like `columns`, all of `border`/`gutter`/`vline` are read only from `{{< mp-begin >}}`, apply to the whole row, and reset on every `{{< mp-begin >}}` call.

PDF only — for every other format these shortcodes emit nothing (silently), so the column content still renders, just stacked as plain paragraphs instead of side by side.

---

## Table of contents

All three extensions support a `{{< toc >}}` shortcode for HTML and PDF output — place it anywhere in the document body to insert a table of contents at that spot, built from the document's own headings:

```markdown
## Table des matières

{{< toc >}}

# Niveau 1 — Introduction
...
```

- **PDF**: renders as a native `\tableofcontents`, so it only lists headings that actually become numbered/unstarred LaTeX sections — `compte-rendu`'s fixed section labels (Participants, Décisions, Actions, ...) use `\section*` internally and are correctly excluded, leaving just the headings you wrote yourself. Goes 4 levels deep (`#` through `####`, i.e. down to `\paragraph`) — `secnumdepth`/`tocdepth` are both set to `4`.
- **HTML**: renders as a nested list of anchor links to each heading, since these extensions use a fully custom template (`page-layout: custom`) and never emit Quarto's own `$toc$`. Not depth-limited — every heading level is included.
- Other formats (Typst, docx, odt, Markdown, plain text) are not currently supported — the shortcode is silently dropped, with no visible artifact.

> In `lettre`, `::: subject :::` is conventionally written as a level-2 heading (`## {{< meta title >}}`) — it will show up as a table-of-contents entry like any other heading if you add `{{< toc >}}` to a letter.

> Headings are never visibly numbered (empty `\titleformat` label), but `secnumdepth` is kept above 0 regardless — set it to 0 and LaTeX stops `\refstepcounter`-ing headings, so every PDF TOC entry silently links to the same anchor (page 1) instead of its own section. Harmless-looking on a one-page letter, obviously wrong once headings span several pages.

---

## PDF margin overrides

All three extensions support per-document margin overrides for PDF output via YAML metadata, at several levels of granularity — the most specific one set wins:

| Key | Sets | Default |
|---|---|---|
| `margin-inner` (or `margin-left`) | inner / left margin, all pages | `20mm` |
| `margin-outer` (or `margin-right`) | outer / right margin, all pages | `20mm` |
| `margin-top` | top margin, body pages only | `25mm` |
| `margin-bottom` | bottom margin, body pages only | `15mm` |
| `marginx` | `margin-inner` **and** `margin-outer`, if not set individually | — |
| `marginy` | `margin-top` **and** `margin-bottom`, if not set individually | — |
| `margin-all` | all four, if not set by any of the above | — |
| `margins` | CSS-style shorthand for any/all of the four, if not set by any of the above — see below | — |

`margin-left`/`margin-right` are plain synonyms for `margin-inner`/`margin-outer` — none of these extensions set LaTeX's `\twoside` option, so inner always means left and outer always means right; there's no duplex page-parity flip to worry about. Use whichever reads more naturally.

```yaml
# every page gets 15mm on the sides; top/bottom keep their defaults
marginx: 15mm

# same as writing all four margin-* keys explicitly
margin-all: 18mm

# margin-top wins over marginy, which wins over margin-all — bottom falls
# back to margin-all since neither margin-bottom nor marginy set it
margin-all: 10mm
marginy: 15mm
margin-top: 30mm
```

> `margin` (without a suffix) is reserved by Quarto itself (revealjs/typst slide margin, must be a number) — use `margin-all` (or `margins`, below) instead for a plain string like `"20mm"`.

### CSS-style shorthand (`margins:`)

`margins` accepts 1 to 4 space-separated lengths in one string, read the same way CSS resolves `margin`/`padding` shorthand — the broadest, lowest-priority way to set them, so every key in the table above still overrides it where set:

| Form | Meaning |
|---|---|
| `margins: 20mm` | all four sides |
| `margins: "15mm 25mm"` | top & bottom, left & right (`y x`) |
| `margins: "10mm 25mm 15mm"` | top, left & right, bottom (`t x b`) |
| `margins: "10mm 25mm 15mm 30mm"` | top, right, bottom, left, clockwise from top (`t r b l`) |

```yaml
# same page, three equivalent ways to write it
margins: "10mm 25mm 15mm 30mm"
# —
margin-top: 10mm
margin-right: 25mm
margin-bottom: 15mm
margin-left: 30mm
# —
margin-top: 10mm
margin-outer: 25mm
margin-bottom: 15mm
margin-inner: 30mm
```

These can be set at the document level (affects all PDF formats) or under a specific format:

```yaml
format:
  lettre-pdf:
    margin-inner: 30mm
    margin-outer: 30mm
```

> In `lettre` and `compte-rendu`, the first page's top/bottom margins are fixed (sized to accommodate the header/footer area) regardless of `margin-top`/`margin-bottom` — only body pages, from page 2 onward, pick those up. `document` has no such split (see below) — `margin-top`/`margin-bottom` apply to every page, including the first.

`margin-inner`/`margin-outer` also bound the header and footer, not just the body — both are horizontally centered within the same width as the body text, so a header logo or footer line stays aligned with the letter's left/right edges instead of centering on the full page.

### Header/footer spacing

All three extensions also support keys that size the header/footer area itself — independent of `margin-top`/`margin-bottom`, which size the body's margins:

| Key | Sets | Default |
|---|---|---|
| `margin-header` | space from the top of the header text to the top of the page | `5mm` |
| `margin-footer` | space from the bottom of the footer to the bottom of the page | geometry's own built-in footer spacing, if left unset |
| `header-height` | height reserved for the header area (bigger logo, multi-line header, ...) | `15mm` (`lettre`/`compte-rendu`) or `margin-top` (`document`) |

```yaml
margin-header: 10mm    # more breathing room above the header text
margin-footer: 20mm    # generous gap between the footer and the page edge
header-height: 25mm    # taller header area, e.g. for a bigger logo
```

`margin-footer` and the body's own bottom margin (`margin-bottom`, or `25mm`/`15mm` default depending on the extension and page) share the same budget — asking for more footer space than that budget allows still compiles, but pushes the footer past the page edge rather than shrinking the body area to make room. The same applies to `header-height`: a value much larger than the page can accommodate alongside its other content can push body content off the page or otherwise break layout (e.g. a `longtable` that doesn't have room to fit) — keep it proportional to the page and header content.

### `document`-only extras

`document` also supports one additional margin key — PDF-only, and specific to this extension (`lettre`/`compte-rendu` don't read it):

| Key | Sets | Priority / fallback |
|---|---|---|
| `margin-top-first` | top offset before the body text starts, page 1 only | falls back to `margin-top`, then `45mm` |

```yaml
margin-top-first: 5mm  # pull the body text up close to the header, page 1 only
```

`document` has a single `\geometry{}` call that applies to every page — unlike `lettre`/`compte-rendu`, there's no separate first-page geometry to hardcode page-1 values into. `margin-top-first` fills that gap for the one thing that does need to differ on page 1: how far down the body text starts, to leave room for the header above it.

---

## PDF class customization

For PDF output, an optional `_parts/custom.cls` at the project root (next to `_quarto.yml`) can override anything from `quarto-lettre.cls` or the format's own `layout.tex` preamble — fonts, `\titleformat`, packages, custom environments, and so on. It's loaded last, right before `\begin{document}`, so it wins over both. Absent by default — no-op if the file doesn't exist.

```tex
% _parts/custom.cls
\titleformat{\section}
  {\normalfont\QLheadingfont\LARGE\bfseries\color{red}}{\thesection}{0pt}{}
  [\vspace{0.5em}\titlerule]
```

Unlike the generated `quarto-lettre.cls`/`.tex` at the project root (removed after every render by `clean-artifacts.lua`), `_parts/custom.cls` is user-owned content and is never touched by cleanup — same guarantee as the `_parts/*.qmd` overrides above.

A `tex-custom` metadata key (raw LaTeX, as a `|` block scalar) does the same thing, inline in the document's or project's YAML instead of a separate file — handy for a one-document tweak, or for keeping everything in `_quarto.yml`. It's injected right after `_parts/custom.cls`, so when both are present, `tex-custom` wins — same "metadata always wins" priority as everywhere else in this extension:

```yaml
tex-custom: |
  \titleformat{\section}
    {\normalfont\QLheadingfont\LARGE\bfseries\color{red}}{\thesection}{0pt}{}
    [\vspace{0.5em}\titlerule]
```

---

## Tables (PDF)

Every Markdown table (and lettre/compte-rendu's own label/value divs like `::: ref :::` or `::: actions :::`, which render as a table internally) gets a very thin, light-gray rule between each body row in PDF output — pandoc's own table rendering only rules the table's top/bottom edge and the header separator, leaving body rows unseparated. This isn't configurable per-document; it's baked into every PDF table via `\QLrowrule` (defined in `quarto-lettre.cls`) and a `tablerule.lua` filter that splices it between rows.

---

## Bibliography (PDF)

Citations and the bibliography use a shorthand label — the CSL `citation-label` variable — instead of a plain running number: `[@doe99]` renders as `(Doe99)` both at the citation site and in the bibliography's own margin, rather than `(1)`. Generated automatically from the author's surname and the year (no `shorthand`/`label` field needed in the `.bib` entry), and disambiguated with an `a`/`b`/... suffix if two entries would otherwise collide (e.g. two 1999 books by the same author become `Doe99a` / `Doe99b`). Defined in `_extensions/base/resources/biblio.csl`, used only by the `pdf` format in all three extensions — HTML/typst citation rendering is unaffected.

---

## Brand fonts

All three extensions use `theme: none` for HTML (a fully custom template, no Bootstrap) and a fully custom LaTeX `.cls` for PDF, so Quarto's own [brand.yml](https://quarto.org/docs/authoring/brand.html) → CSS/fontspec pipeline never runs there — `typography` in a brand file is otherwise silently ignored in both. This is filled in by hand: the resolved `base`, `headings`, and `monospace` font families are read from the active brand and applied per format.

This works with any brand — the project's own (`brand: _brand/_brand.yml` in `_quarto.yml` or document front matter) if set, otherwise the extensions' own bundled default (`_extensions/base/brand.yml`, Jura) via `contributes.metadata.project.brand` — and needs nothing from the document itself; a document with no brand configured at all gets no font changes, silently.

- **HTML**: the fonts are injected as a Google Fonts `<link>` plus matching `font-family` CSS rules — always works, since the browser fetches them at view time regardless of what's installed on the machine that rendered the document.
- **Typst**: gets brand fonts from Quarto's own typst-brand integration automatically (visible as `#show heading: set text(font: (...))` etc. in the generated `.typ`) — nothing to do there.
- **PDF (LaTeX)**: each font is set with `\setmainfont`/`\setmonofont` (headings via a `\QLheadingfont` hook used inside the class's `\titleformat`), but only if `\IfFontExistsTF` confirms it's actually installed on the machine doing the render — otherwise that assignment is a silent no-op and the class's default (Libertinus) stays in effect. Unlike HTML's web fonts, a PDF font must be present locally to be embedded, and LaTeX's `fontspec` raises a **hard compile error** (not a fallback) for a family it can't find — this guard is what keeps a brand referencing an uninstalled Google Font from breaking the build.
- **docx and odt do not pick up brand fonts** — no dynamic mechanism for either (the reference doc's styles are static).

---

## French guillemets in HTML

In LaTeX and Typst output, smart double quotes (`"..."`) are always rendered as French guillemets (« ... »). In HTML output this is opt-in via the `french-quotes` metadata key — enabled by default:

```yaml
format:
  lettre-html:
    french-quotes: true
```

Set it at the document level or under a specific HTML format to override the extension's default.

---

## Render

```bash
quarto render my-letter.qmd
```

---

## Extension structure

```
_extensions/
├── base/                          # Shared resources (not a format)
│   ├── _filters/page.lua          # ::: header1/footer :::, part fallback (all 3), lettre-only body/margins, HTML+PDF brand fonts, quote style
│   ├── _filters/toc.lua           # {{< toc >}} rendering — wired at the post-quarto entry point, after shortcode resolution
│   ├── _filters/tablerule.lua     # thin rule between PDF table rows (\QLrowrule, defined in quarto-lettre.cls)
│   ├── _shortcodes/toc.lua        # {{< toc >}} shortcode — drops a placeholder for _filters/toc.lua to expand
│   ├── _shortcodes/minipage.lua   # {{< mp-begin/next/end >}} — side-by-side PDF columns (document only)
│   ├── brand.yml                  # default brand (contributed to every project via _extension.yml)
│   ├── parts/                     # bundled default section content (see _parts/ above)
│   │   └── <div>.qmd              # header1.qmd, footer.qmd (all 3); from/date/... (lettre only)
│   ├── md/
│   │   ├── _filters/tables.lua    # Markdown table filter
│   │   └── layout.md              # Markdown template
│   ├── plain/layout.txt           # Plain text template
│   └── resources/biblio.csl       # CSL bibliography style
│
├── lettre/
│   ├── _extension.yml
│   ├── _filters/validate.lua      # Validates required divs and metadata
│   ├── html/{layout.html,css/}
│   ├── pdf/{layout.tex,quarto-lettre.cls,_filters/,_partials/}
│   ├── typst/{layout.typ,_filters/,_partials/}
│   ├── docx/{reference.docx,_filters/}
│   └── odt/reference.odt
│
├── compte-rendu/
│   ├── _extension.yml
│   ├── _filters/validate.lua
│   ├── html/{layout.html,css/}
│   ├── pdf/{layout.tex,quarto-lettre.cls,_filters/,_partials/}
│   ├── typst/{layout.typ,_filters/,_partials/}
│   └── md/_filters/divs.lua
│
└── document/
    ├── _extension.yml
    ├── _filters/validate.lua
    ├── html/{layout.html,css/}
    ├── pdf/{layout.tex,quarto-lettre.cls,_filters/,_partials/}
    └── typst/{_filters/,_partials/}
```

---

## Author

Chris Mann — [chris@lesgrandsvoisins.com](mailto:chris@lesgrandsvoisins.com)
