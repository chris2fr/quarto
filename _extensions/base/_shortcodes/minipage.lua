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
-- (`width=0.3`) or a percentage (`width=30%`, equivalent) — defaulting to
-- 0.45 (two columns with a bit of `\hfill` gap between them).
--
-- LaTeX/PDF only, like the rest of this extension's environment/command
-- machinery — for every other format these emit nothing (silently) rather
-- than leaking raw LaTeX as visible text.
local function width_arg(kwargs)
  -- kwargs['width'] is present (as an empty node, not nil) even when the
  -- shortcode is called without a width= argument, so truthiness alone
  -- can't detect "not passed" — check the stringified result instead.
  local width = kwargs['width'] and pandoc.utils.stringify(kwargs['width']) or ''
  if width == '' then width = '0.45' end
  local pct = width:match('^(%d+%.?%d*)%%$')
  if pct then width = tostring(tonumber(pct) / 100) end
  return width .. '\\textwidth'
end

return {
  ['mp-begin'] = function(args, kwargs, meta)
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
