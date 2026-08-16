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
--
-- A row-ending `\\` isn't the only `\\` in the body: a cell with hard line
-- breaks (from trailing `\` in the Markdown) and a constrained column width
-- (tbl-colwidths) gets wrapped by pandoc in `\begin{minipage}...\end{minipage}`,
-- and *those* internal line breaks are also literal `\\`. Splicing
-- \QLrowrule after one lands it inside the minipage, where \noalign (which
-- \QLrowrule expands to) is illegal outside a tabular alignment and LaTeX
-- dies with "Misplaced \noalign". So only splice at minipage depth 0.
function Table(el)
  if not FORMAT:match('latex') then return nil end
  local latex = pandoc.write(pandoc.Pandoc({ el }), 'latex')
  local head, body = latex:match('^(.-\\endlastfoot\n)(.*)$')
  if not head then return nil end

  local out = {}
  local depth = 0
  for line in (body .. '\n'):gmatch('([^\n]*)\n') do
    local _, begins = line:gsub('\\begin{minipage}', '')
    local _, ends = line:gsub('\\end{minipage}', '')
    depth = depth + begins - ends
    table.insert(out, line)
    if depth == 0 and line:match('\\\\%s*$') then
      table.insert(out, '\\QLrowrule')
    end
  end
  body = table.concat(out, '\n')
  -- The loop above also lands a rule after the *last* body row, right where
  -- \bottomrule (declared up in \endlastfoot, but placed by longtable at the
  -- table's true end) is about to print — doubling up into a heavy-looking
  -- close. Drop that one trailing rule; every other row still gets one.
  body = body:gsub('\\QLrowrule\n%s*\\end{longtable', '\\end{longtable')
  return pandoc.RawBlock('latex', head .. body)
end
