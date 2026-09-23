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
-- first column, `{{< mp-next >}}` closes it, inserts a gap, and opens the
-- next one, and `{{< mp-end >}}` closes the last one. Each takes an
-- optional `width` kwarg — either a bare fraction of `\textwidth`
-- (`width=0.3`) or a percentage (`width=30%`, equivalent) — which overrides
-- everything below for that one column.
--
-- Without an explicit `width`, `{{< mp-begin columns=N >}}` sets a shared
-- default of 0.95/N for every column in the row (leaving some width for the
-- gaps) — so a 3- or 4-column row doesn't need `width=` repeated on every
-- shortcode call. This can't be fully automatic (counting the
-- `{{< mp-next >}}` calls that follow `{{< mp-begin >}}`) since shortcodes
-- are expanded as they're encountered, with no lookahead into what comes
-- later in the document — `columns=N` is the one number you still have to
-- state up front. Plain two-column rows with no `columns=` keep a flat
-- 0.48 default.
--
-- `{{< mp-begin border=true >}}` wraps every column of the row in `\fbox{}`
-- (a thin rule, `\fboxsep`/`\fboxrule` spacing — the LaTeX default, no
-- extra package needed).
--
-- `{{< mp-begin gutter=1em >}}` replaces the `\hfill` between columns with
-- a fixed `\hspace{1em}` — any LaTeX length (`1em`, `5mm`, ...). Without
-- it, the gap stays flexible (`\hfill`, fills whatever space the column
-- widths leave). A fixed gutter is subtracted from nothing automatically —
-- widths and gutter still have to add up to `\textwidth` or less yourself,
-- same as choosing `width=` by hand.
--
-- `{{< mp-begin vline=true >}}` draws a `\vrule` in the gap instead of (or
-- centered within, if `gutter` is also set) the plain space. A bare
-- `\vrule` with no explicit height/depth stretches to match the tallest
-- box on its line automatically, so it spans exactly as tall as the row's
-- columns without any manual height calculation.
--
-- `columns`/`border`/`gutter`/`vline` are read only by `{{< mp-begin >}}`
-- and apply to the whole row; they reset on every `{{< mp-begin >}}` call
-- (even to "off"/unset when omitted) so one row's settings never leak into
-- the next.
local row_default_width = nil
local row_border = false
local row_gutter = nil
local row_vline = false

local function kwarg(kwargs, key)
  return kwargs[key] and pandoc.utils.stringify(kwargs[key]) or ''
end

local function is_truthy(s)
  return s ~= '' and s ~= 'false' and s ~= '0'
end

local function width_arg(kwargs)
  -- kwargs['width'] is present (as an empty node, not nil) even when the
  -- shortcode is called without a width= argument, so truthiness alone
  -- can't detect "not passed" — check the stringified result instead.
  local width = kwarg(kwargs, 'width')
  local pct = width:match('^(%d+%.?%d*)%%$')
  if pct then width = tostring(tonumber(pct) / 100) end
  if width == '' then width = row_default_width or '0.48' end
  return width .. '\\textwidth'
end

local function border_open()
  return row_border and '\\fbox{' or ''
end

local function border_close()
  return row_border and '}' or ''
end

local function gutter_glue()
  local rule = row_vline and '\\vrule ' or ''
  if row_gutter then
    local half = '\\hspace{\\dimexpr ' .. row_gutter .. '/2\\relax}'
    return row_vline and (half .. rule .. half) or ('\\hspace{' .. row_gutter .. '}')
  end
  return row_vline and ('\\hfill' .. rule .. '\\hfill') or '\\hfill'
end

return {
  ['mp-begin'] = function(args, kwargs, meta)
    local n = tonumber(kwarg(kwargs, 'columns'))
    row_default_width = n and string.format('%.3f', 0.95 / n) or nil

    row_border = is_truthy(kwarg(kwargs, 'border'))
    local gutter = kwarg(kwargs, 'gutter')
    row_gutter = gutter ~= '' and gutter or nil
    row_vline = is_truthy(kwarg(kwargs, 'vline'))

    if not quarto.doc.is_format("latex") then return pandoc.Str('') end
    return pandoc.RawInline('tex',
      border_open() .. '\\begin{minipage}[t]{' .. width_arg(kwargs) .. '}')
  end,
  ['mp-next'] = function(args, kwargs, meta)
    if not quarto.doc.is_format("latex") then return pandoc.Str('') end
    return pandoc.RawInline('tex',
      '\\end{minipage}' .. border_close() .. gutter_glue() ..
      border_open() .. '\\begin{minipage}[t]{' .. width_arg(kwargs) .. '}')
  end,
  ['mp-end'] = function(args, kwargs, meta)
    if not quarto.doc.is_format("latex") then return pandoc.Str('') end
    return pandoc.RawInline('tex', '\\end{minipage}' .. border_close())
  end,
}
