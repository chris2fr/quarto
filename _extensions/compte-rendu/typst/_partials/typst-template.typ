#import "quarto-meet.typ": ql-page-setup

#let compte-rendu(
  lang:        "fr",
  paper:       "a4",
  fontsize:    11pt,
  page1-header: none,
  page-footer: none,
  doc,
) = ql-page-setup(
  lang:        lang,
  paper:       paper,
  fontsize:    fontsize,
  margin:      (top: 25mm, bottom: 25mm, left: 20mm, right: 20mm),
  page1-header: page1-header,
  page-footer: page-footer,
  doc,
)
