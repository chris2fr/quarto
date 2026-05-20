// Compte-rendu template

#let compte-rendu(
  lang: "fr",
  paper: "a4",
  fontsize: 11pt,
  page-header: none,
  page-footer: none,
  doc,
) = {
  set page(
    paper: paper,
    margin: (top: 20mm, bottom: 30mm, left: 25mm, right: 25mm),
    header: if page-header != none {
      align(center, text(size: 9pt, page-header))
    },
    footer: context {
      let pg = counter(page).get().first()
      align(center, text(size: 9pt)[
        #if pg > 1 [#pg \ ]
        #if page-footer != none { page-footer }
      ])
    },
    numbering: none,
  )
  set text(lang: lang, size: fontsize)
  set par(justify: true, leading: 0.65em, spacing: 1.2em)
  doc
}

#set table(inset: 6pt, stroke: none)
