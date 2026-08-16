-- A crossref'd float (`{#tbl-xxx}`/`{#fig-xxx}`, most commonly this
-- extension's own `::: {#tbl-xxx .list-table}`) doesn't stay a plain pandoc
-- Table/Figure once quarto's own crossref numbering has run: it gets
-- wrapped in quarto's internal "FloatRefTarget" custom Div (identified by
-- its `__quarto_custom_type` attribute), containing two "scaffold" sub-Divs
-- — one holding the actual Table/Figure, the other its caption as a plain
-- Plain/Para block. html/pdf/typst all have a native quarto renderer for
-- that structure; `markdown_strict`/`plain` (this extension's own `md` and
-- `plain` formats) don't, so quarto's own fallback silently drops the
-- caption and emits a placeholder plus a console warning per float —
-- confirmed by rendering a `.list-table` with an id to lettre-md/lettre-plain
-- and diffing against one without.
--
-- Registered at `post-quarto` (only FloatRefTarget exists that late) for
-- just the `md`/`plain` format blocks in each extension's _extension.yml —
-- html/pdf/typst/docx/odt already render this correctly and don't need it.
--
-- A quarto custom node reports `.t == 'Div'` for plain field access, but
-- isn't actually dispatched through pandoc's own type-based filter-table
-- routing (confirmed: a top-level `function Div(el)` here is never called
-- for one, even though it's plainly visible via a manual Pandoc(doc)
-- content walk) — so this can't be a `Div` filter function; it has to walk
-- doc.blocks by hand and rebuild them, same as ../_filters/toc.lua's own
-- collect_tables does for the same underlying structure.
local function is_float_target(el)
  return el.t == 'Div' and el.attributes and el.attributes.__quarto_custom_type == 'FloatRefTarget'
end

-- Flattens the wrapper back into ordinary blocks: caption paragraph, then
-- the table/figure.
local function flatten(div)
  local table_blocks, caption_blocks = {}, {}
  for _, scaffold in ipairs(div.content) do
    for _, inner in ipairs(scaffold.content or {}) do
      if inner.t == 'Table' or inner.t == 'Figure' then
        table.insert(table_blocks, inner)
      else
        table.insert(caption_blocks, inner)
      end
    end
  end
  local out = {}
  for _, b in ipairs(caption_blocks) do table.insert(out, b) end
  for _, b in ipairs(table_blocks) do table.insert(out, b) end
  return out
end

-- Only recurses into genuine Div containers (this extension's own
-- from/date/.../body wrapper divs, and a FloatRefTarget's own scaffolding)
-- rather than blindly reassigning `.content` on any block type, since that
-- field means something else (Inlines, not Blocks) for a Para/Plain and
-- isn't necessarily safe to overwrite on every element type.
local function process_blocks(blocks)
  local out = {}
  for _, b in ipairs(blocks) do
    if is_float_target(b) then
      for _, x in ipairs(flatten(b)) do table.insert(out, x) end
    else
      if b.t == 'Div' then b.content = process_blocks(b.content) end
      table.insert(out, b)
    end
  end
  return out
end

function Pandoc(doc)
  doc.blocks = process_blocks(doc.blocks)
  return doc
end
