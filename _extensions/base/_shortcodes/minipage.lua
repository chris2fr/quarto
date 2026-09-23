-- {{< mp-begin >}} / {{< mp-next >}} / {{< mp-end >}} — raw LaTeX
-- `\begin{minipage}`/`\end{minipage}`/`\hfill` boilerplate for a row of
-- side-by-side minipage columns, so it doesn't have to be retyped verbatim
-- at every use (see test/document.qmd). Everything must stay inline in the
-- same paragraph as the content around it — a block-level raw div would
-- force a paragraph break and stack the columns instead of placing them
-- side by side (see latex-environment.lua's writeSpanEnvironments for the
-- same constraint on the .minipage span/div mechanism).
--
-- {{< mp-begin >}}content{{< mp-next >}}content{{< mp-end >}} opens the
-- first column, `{{< mp-next >}}` closes it, inserts `\hfill`, and opens
-- the next one, and `{{< mp-end >}}` closes the last one. Each takes an
-- optional `width` kwarg — either a bare fraction of `\textwidth`
-- (`width=0.3`) or a percentage (`width=30%`, equivalent) — which overrides
-- everything below for that one column.
--
-- Without an explicit `width`, `{{< mp-begin columns=N >}}` sets a shared
-- default of 0.9/N for every column in the row (0.9 rather than 1, leaving
-- some width for the `\hfill` gaps) — so a 3- or 4-column row doesn't need
-- `width=` repeated on every shortcode call. This can't be fully automatic
-- (counting the `{{< mp-next >}}` calls that follow `{{< mp-begin >}}`)
-- since shortcodes are expanded as they're encountered, with no lookahead
-- into what comes later in the document — `columns=N` is the one number
-- you still have to state up front. Plain two-column rows with no
-- `columns=` keep the previous flat 0.45 default.
local row_default_width = nil

local function width_arg(kwargs)
  -- kwargs['width'] is present (as an empty node, not nil) even when the
  -- shortcode is called without a width= argument, so truthiness alone
  -- can't detect "not passed" — check the stringified result instead.
  local width = kwargs['width'] and pandoc.utils.stringify(kwargs['width']) or ''
  local pct = width:match('^(%d+%.?%d*)%%$')
  if pct then width = tostring(tonumber(pct) / 100) end
  if width == '' then width = row_default_width or '0.48' end
  return width .. '\\textwidth'
end

return {
  ['mp-begin'] = function(args, kwargs, meta)
    local columns = kwargs['columns'] and pandoc.utils.stringify(kwargs['columns']) or ''
    local n = tonumber(columns)
    row_default_width = n and string.format('%.3f', 0.95 / n) or nil

    if not quarto.doc.is_format("latex") then return pandoc.Str('') end
    return pandoc.RawInline('tex', '\\begin{minipage}[t]{' .. width_arg(kwargs) .. '}')
  end,
  ['mp-next'] = function(args, kwargs, meta)
    if not quarto.doc.is_format("latex") then return pandoc.Str('') end
    return pandoc.RawInline('tex', '\\end{minipage}\\hfill\\begin{minipage}[t]{' .. width_arg(kwargs) .. '}')
  end,
  ['mp-end'] = function(args, kwargs, meta)
    if not quarto.doc.is_format("latex") then return pandoc.Str('') end
    return pandoc.RawInline('tex', '\\end{minipage}')
  end,
}
