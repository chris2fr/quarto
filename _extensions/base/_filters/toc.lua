-- Expands the `{{< toc >}}` shortcode's placeholder Div (produced by
-- ../_shortcodes/toc.lua, class quarto-lettre-toc) into a format-native
-- table of contents.
--
-- This has to be its own filter, wired in via the `at: post-quarto` entry
-- point (see each extension's _extension.yml), rather than folded into
-- page.lua: page.lua's own filters attach at the default pre-quarto entry
-- point, which runs *before* quarto resolves shortcodes. At that point
-- `{{< toc >}}` is still an unexpanded shortcode, not yet a Div — this
-- filter needs to run after quarto's own shortcode-resolution pass, so it
-- has to sit at a later entry point.
--
-- LaTeX gets a real \tableofcontents, populated by the class's own
-- \section/\subsection machinery — starred fallback headings (e.g.
-- compte-rendu's `\section*{Décisions}`) never call \addcontentsline, so
-- they're correctly excluded, leaving only headings the author actually
-- wrote in the body. HTML gets a hand-built nested list of anchor links,
-- since these templates are fully custom (page-layout: custom) and never
-- render pandoc's own $toc$ variable. Other formats are out of scope for now
-- and the marker is simply dropped.
local function collect_headers(doc)
  local headers = {}
  doc:walk({ Header = function(h) table.insert(headers, h) end })
  return headers
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
  return doc:walk({
    Div = function(div)
      if not div.classes:includes('quarto-lettre-toc') then return nil end
      local level = tonumber(div.attributes.level)
      if FORMAT:match('latex') then
        if level then
          -- tocdepth is only consulted when \tableofcontents reads back the
          -- .toc file, so scoping it here doesn't disturb the document-wide
          -- depth (5, set in each format's .cls/layout.tex) used elsewhere.
          return pandoc.RawBlock('latex', '\\begingroup\\setcounter{tocdepth}{'
            .. level .. '}\\tableofcontents\\endgroup')
        end
        return pandoc.RawBlock('latex', '\\tableofcontents')
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
