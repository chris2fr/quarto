-- Very thin, light-gray rule between each body row of a Markdown table, PDF
-- only (\QLrowrule, defined in quarto-lettre.cls) — pandoc's own longtable
-- output only rules the table edges and the header separator
-- (\toprule/\midrule/\bottomrule), leaving body rows unseparated.
--
-- Re-renders the table through pandoc's own LaTeX writer in isolation (same
-- output pandoc would have produced inline — table rendering has no
-- cross-block state to lose) and splices \QLrowrule in as literal text after
-- each body row's `\\`. Deliberately text-splicing rather than redefining
-- `\\` inside the table: tried that first (locally, via \endhead), and it
-- fights longtable/booktabs' internal alignment bookkeeping badly enough to
-- corrupt the table ("Misplaced \noalign" at \bottomrule).
--
-- \endlastfoot marks the end of the (possibly absent, for an unheadered
-- table) repeating header/footer setup and the start of the actual body
-- rows; a table without one (no header row — not producible by a Markdown
-- pipe table, but conceivably by a raw LaTeX table) is left untouched.
function Table(el)
  if not FORMAT:match('latex') then return nil end
  local latex = pandoc.write(pandoc.Pandoc({ el }), 'latex')
  local head, body = latex:match('^(.-\\endlastfoot\n)(.*)$')
  if not head then return nil end
  body = body:gsub('\\\\\n', '\\\\\n\\QLrowrule\n')
  return pandoc.RawBlock('latex', head .. body)
end
