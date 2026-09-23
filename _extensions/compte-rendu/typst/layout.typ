// ── boilerplate kept from Pandoc default ─────────────────────────────────────

#let horizontalrule = line(start: (25%,0%), end: (75%,0%))

#show terms: it => {
  it.children
    .map(child => [
      #strong[#child.term]
      #block(inset: (left: 1.5em, top: -0.4em))[#child.description]
    ])
    .join()
}

#set table(inset: 6pt, stroke: none)

$for(header-includes)$
$header-includes$
$endfor$

// ── page ─────────────────────────────────────────────────────────────────────

#set page(
  paper: "$if(papersize)$$papersize$$else$a4$endif$",
  margin: (top: 25mm, bottom: 25mm, left: 20mm, right: 20mm),
$if(page1-header)$
  header: align(center, text(size: 9pt)[
$page1-header$
  ]),
$endif$
  footer: context {
    let pg = counter(page).get().first()
    align(center, text(size: 9pt)[
      #if pg > 1 [#pg \ ]
$if(page-footer)$$page-footer$$endif$
    ])
  },
  numbering: none,
)

// ── typography ────────────────────────────────────────────────────────────────

#set text(
  lang:  "$if(lang)$$lang$$else$fr$endif$",
  size:  $if(fontsize)$$fontsize$$else$11pt$endif$,
$if(mainfont)$
  font: ("$mainfont$",),
$endif$
)

#set par(justify: true, leading: 0.65em, spacing: 1.2em)

// ── body ─────────────────────────────────────────────────────────────────────

$for(include-before)$
$include-before$

$endfor$

$body$

$for(include-after)$
$include-after$
$endfor$
