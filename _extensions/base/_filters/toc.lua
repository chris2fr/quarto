-- Expands the `{{< toc >}}`/`{{< lot >}}` shortcodes' placeholder Divs
-- (produced by ../_shortcodes/toc.lua, classes quarto-lettre-toc /
-- quarto-lettre-lot) into a format-native table of contents / list of
-- tables.
--
-- This has to be its own filter, wired in via the `at: post-quarto` entry
-- point (see each extension's _extension.yml), rather than folded into
-- page.lua: page.lua's own filters attach at the default pre-quarto entry
-- point, which runs *before* quarto resolves shortcodes. At that point
-- `{{< toc >}}` is still an unexpanded shortcode, not yet a Div — this
-- filter needs to run after quarto's own shortcode-resolution pass, so it
-- has to sit at a later entry point.
--
-- LaTeX gets \QLtoc (defined in each format's quarto-lettre.cls), populated
-- by the class's own \section/\subsection machinery — starred fallback
-- headings (e.g. compte-rendu's `\section*{Décisions}`) never call
-- \addcontentsline, so they're correctly excluded, leaving only headings the
-- author actually wrote in the body. HTML gets a hand-built nested list of
-- anchor links, since these templates are fully custom (page-layout: custom)
-- and never render pandoc's own $toc$ variable. Other formats are out of
-- scope for now and the marker is simply dropped.
--
-- Neither side prints its own title: a `{{< toc >}}` has no heading of its
-- own, and it's up to the author to put one in front (e.g. `## Sommaire
-- {.unnumbered .unlisted}`) if they want one — which means that title must
-- not leak into a *listing* (its own, or another `{{< toc >}}`'s).
-- `.unnumbered` alone isn't enough for that: pandoc still emits an
-- \addcontentsline for it (just without a number — e.g. an unnumbered
-- "Préface" that's still meant to appear in the printed toc). `.unlisted` is
-- pandoc's own class for "leave this out of the toc entirely", which it
-- honours by omitting \addcontentsline outright for LaTeX — skipped here for
-- the same reason, to keep the hand-built HTML list consistent with it.
--
-- `{{< lot >}}` reuses none of the above: a repeatable list of tables can't
-- reuse titletoc's \startcontents/\printcontents trick the way \QLtoc does —
-- tested directly (a standalone LaTeX file, titletoc alone): naming a second
-- contents list "lof"/"lot" doesn't bind it to \addcontentsline{lof}/{lot}
-- entries the way "toc" is bound to section entries; titletoc's own
-- \startlist/\printlist (the *real* multi-list API, one rung below
-- \startcontents/\printcontents) does target lof/lot correctly, but silently
-- drops the first entry of the run. So this hand-builds the list instead: at
-- `Pandoc(doc)` time (after quarto's own crossref/numbering pass has run,
-- since this is a post-quarto filter) every Table with a real id already has
-- a working `\label{tbl-xxx}` in its `\caption` — reuse that directly via
-- `\ref`/`\pageref` rather than reimplementing titletoc's page-tracking.
--
-- This only sees tables with an id set on the pandoc Table node itself,
-- which in practice means `::: {#tbl-xxx .list-table}` — this extension's
-- own table mechanism, converted to a native Table with that id attached
-- early (during quarto's own list-table parsing). A plain pandoc table
-- captioned `: text {#tbl-xxx}` relies on quarto's crossref pass to lift
-- `{#tbl-xxx}` out of the caption text and onto the table — confirmed by
-- testing that this happens too late for a post-quarto filter to see (the
-- Table's `.identifier` is still empty here); such a table is silently
-- absent from `{{< lot >}}` rather than listed with no id to link to.
local function collect_headers(doc)
  local headers = {}
  doc:walk({ Header = function(h)
    if not h.classes:includes('unlisted') then table.insert(headers, h) end
  end })
  return headers
end

-- A crossref'd `::: {#tbl-xxx .list-table}` doesn't stay a plain pandoc
-- Table with a populated .caption — quarto wraps it in its own internal
-- "FloatRefTarget" custom Div (attribute __quarto_custom_type), containing
-- two "scaffold" sub-Divs: one holding the Table itself (its .caption is
-- empty; the id lives on the Table node), the other holding the caption
-- text as a plain Plain/Para block. Confirmed by dumping the AST at this
-- filter's own stage — .caption is a dead end here, so this reaches into
-- the scaffold structure directly instead. Filtered to "tbl-" ids: the same
-- FloatRefTarget wrapping is presumably also how quarto handles numbered
-- figures (fig-xxx), which this function isn't collecting.
local function collect_tables(doc)
  local tables = {}
  local function scan(el)
    if el.t == 'Div' and el.attributes and el.attributes.__quarto_custom_type == 'FloatRefTarget' then
      local id, caption
      for _, scaffold in ipairs(el.content) do
        for _, inner in ipairs(scaffold.content or {}) do
          if inner.t == 'Table' and inner.identifier ~= '' then
            id = inner.identifier
          elseif inner.t == 'Plain' or inner.t == 'Para' then
            caption = inner.content
          end
        end
      end
      if id and id:match('^tbl%-') then
        table.insert(tables, { identifier = id, caption = caption or pandoc.Inlines({}) })
      end
    end
    for _, c in ipairs(el.content or {}) do
      if c.t then scan(c) end
    end
  end
  for _, b in ipairs(doc.blocks) do scan(b) end
  return tables
end

local function to_latex(inlines)
  return pandoc.write(pandoc.Pandoc({ pandoc.Plain(inlines) }), 'latex'):gsub('\n$', '')
end

-- \tablename is whatever word the document's own \caption already uses
-- (set by babel/the class — "Table" or "Tableau" depending on locale), kept
-- in sync rather than hard-coding either.
local function render_lot_latex(tables)
  if #tables == 0 then return {} end
  local lines = {}
  for _, t in ipairs(tables) do
    table.insert(lines,
      '\\noindent\\tablename~\\ref{' .. t.identifier .. '} : ' .. to_latex(t.caption)
      .. '\\dotfill\\pageref{' .. t.identifier .. '}\\par')
  end
  return pandoc.RawBlock('latex', table.concat(lines, '\n\\smallskip\n'))
end

local function render_lot_html(tables)
  if #tables == 0 then return {} end
  local items = {}
  for _, t in ipairs(tables) do
    table.insert(items, { pandoc.Plain({ pandoc.Link(t.caption, '#' .. t.identifier) }) })
  end
  return pandoc.Div({ pandoc.BulletList(items) }, pandoc.Attr('', { 'lot' }))
end

-- Nest a flat, in-order header list into a tree following heading levels,
-- e.g. [h1, h2, h2, h1] -> [{h1, children={h2, h2}}, {h1, children={}}].
local function nest_headers(headers)
  local root = {}
  local stack = { { level = 0, children = root } }
  for _, h in ipairs(headers) do
    while #stack > 1 and stack[#stack].level >= h.level do
      table.remove(stack)
    end
    local item = { header = h, children = {} }
    table.insert(stack[#stack].children, item)
    table.insert(stack, { level = h.level, children = item.children })
  end
  return root
end

local function render_toc_items(items)
  local list_items = {}
  for _, item in ipairs(items) do
    local h = item.header
    local target = h.identifier ~= '' and pandoc.Link(h.content, '#' .. h.identifier)
                 or pandoc.Span(h.content)
    local blocks = { pandoc.Plain({ target }) }
    if #item.children > 0 then
      table.insert(blocks, pandoc.BulletList(render_toc_items(item.children)))
    end
    table.insert(list_items, blocks)
  end
  return list_items
end

function Pandoc(doc)
  local headers = collect_headers(doc)
  local tables = collect_tables(doc)
  return doc:walk({
    Div = function(div)
      if div.classes:includes('quarto-lettre-lot') then
        if FORMAT:match('latex') then return render_lot_latex(tables)
        elseif FORMAT:match('html') then return render_lot_html(tables)
        end
        return {}
      end
      if not div.classes:includes('quarto-lettre-toc') then return nil end
      local level = tonumber(div.attributes.level)
      if FORMAT:match('latex') then
        -- \QLtoc (quarto-lettre.cls) takes the same depth \tableofcontents
        -- would via tocdepth, but as an explicit argument rather than a
        -- counter to scope — see \QLtoc's own definition for why plain
        -- \tableofcontents can't be reused here for a second/third {{< toc >}}.
        return pandoc.RawBlock('latex', level and ('\\QLtoc[' .. level .. ']') or '\\QLtoc')
      elseif FORMAT:match('html') then
        local capped = headers
        if level then
          capped = {}
          for _, h in ipairs(headers) do
            if h.level <= level then table.insert(capped, h) end
          end
        end
        local tree = nest_headers(capped)
        if #tree == 0 then return {} end
        return pandoc.Div({ pandoc.BulletList(render_toc_items(tree)) }, pandoc.Attr('', { 'toc' }))
      end
      return {}
    end
  })
end
