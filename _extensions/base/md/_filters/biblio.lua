-- Quarto always runs pandoc's own citeproc as a distinct final pass,
-- strictly *after* every extension-registered Lua filter regardless of
-- `at:` — confirmed with `--verbose`: "Running filter main.lua" (which is
-- where every `pre-quarto`/`post-quarto`/... entry point this extension
-- can hook into actually lives) completes, and only then "Running filter
-- citeproc" starts. So no `_extension.yml` filter position ever sees the
-- resolved CSLReferences AST — by the time any of them run, bibliography
-- citations are still bare `Cite` nodes and `Div#refs` is still empty.
--
-- To turn that resolved bibliography into a markdown-native
-- DefinitionList instead of citeproc's generic Div/Span "left-margin"
-- layout (which the markdown writer can only reproduce as raw
-- `<span class="...">` HTML — the thing this filter exists to avoid), this
-- filter runs citeproc itself, early enough to still intercept the
-- result: it re-invokes the same `pandoc` binary as a subprocess
-- (`-f json -t json --citeproc`) on the whole document, then rewrites the
-- resulting Div#refs before quarto's own trailing citeproc pass ever
-- starts. That trailing pass is turned off via `citeproc: false` in each
-- extension's md format so it doesn't run a second time.
--
-- Doing this at `post-quarto` (rather than any earlier entry point) is
-- what makes it safe to blanket-resolve every remaining `Cite` node in the
-- document: quarto's own crossref system (`@fig-x`, `@tbl-x`, ...) runs
-- its own Cite-consuming filters between `pre-quarto` and `post-quarto`
-- (`quarto_crossref_filters` in quarto's own main.lua) and replaces those
-- with plain text/links well before `post-quarto` — verified by rendering
-- a doc with both a `@fig-x` crossref and a bibliography citation and
-- logging every remaining `Cite` node at `post-quarto`: only the
-- bibliography one was still there. Any earlier entry point would risk
-- running citeproc over still-unresolved crossref citations too.
--
-- citeproc renders the numeric-label bibliography (biblio.csl, used by the
-- md format of lettre/document/compte-rendu) as a Div#refs of per-entry
-- Divs, each holding one Para built from two inline Spans —
-- .csl-left-margin (the "(1)." label) and .csl-right-inline (the entry
-- text) — pandoc's own generic layout for CSL's "left-margin"
-- hanging-indent display, meant for writers with span/div support (HTML,
-- LaTeX via CSLLeftMargin/CSLRightInline macros). Rebuilding each entry as
-- one DefinitionList item (term = label, definition = entry text) renders
-- with plain `term\n:   definition` markdown syntax instead.

-- Same convention as ../_filters/shorthand.lua's own read_relative:
-- metadata paths (bibliography, csl) are relative to the source document's
-- own directory. Our subprocess pandoc runs with an unrelated cwd, so
-- anything relative has to be made absolute before crossing that boundary.
local function abs_path(p, base_dir)
  if pandoc.path.is_absolute(p) then return p end
  if base_dir then return pandoc.path.join({ base_dir, p }) end
  return p
end

local function resolve_meta_paths(meta, base_dir)
  if meta.bibliography then
    if meta.bibliography.t == 'MetaList' then
      local paths = {}
      for _, v in ipairs(meta.bibliography) do
        table.insert(paths, abs_path(pandoc.utils.stringify(v), base_dir))
      end
      meta.bibliography = pandoc.MetaList(paths)
    else
      meta.bibliography = abs_path(pandoc.utils.stringify(meta.bibliography), base_dir)
    end
  end
  if meta.csl then
    meta.csl = abs_path(pandoc.utils.stringify(meta.csl), base_dir)
  else
    -- This file lives at base/md/_filters/biblio.lua; the bundled CSL at
    -- base/resources/biblio.csl, two levels up from here.
    local here = pandoc.path.directory(PANDOC_SCRIPT_FILE or '.')
    meta.csl = pandoc.path.join({ here, '..', '..', 'resources', 'biblio.csl' })
  end
end

local function entry_term_and_def(div)
  local blocks = div.content
  local first = blocks[1]
  local term, def_inlines = {}, {}
  if first and (first.t == 'Para' or first.t == 'Plain') then
    for _, inline in ipairs(first.content) do
      if inline.t == 'Span' and inline.classes:includes('csl-left-margin') then
        term = inline.content
      elseif inline.t == 'Span' and inline.classes:includes('csl-right-inline') then
        for _, x in ipairs(inline.content) do table.insert(def_inlines, x) end
      else
        table.insert(def_inlines, inline)
      end
    end
  end
  local def_blocks = { pandoc.Plain(def_inlines) }
  for i = 2, #blocks do table.insert(def_blocks, blocks[i]) end
  return term, def_blocks
end

local function refs_to_definition_list(el)
  if el.identifier ~= 'refs' then return nil end
  local items = {}
  for _, entry in ipairs(el.content) do
    if entry.t == 'Div' then
      local term, def_blocks = entry_term_and_def(entry)
      table.insert(items, { term, { def_blocks } })
    end
  end
  if #items == 0 then return nil end
  el.content = { pandoc.DefinitionList(items) }
  return el
end

function Pandoc(doc)
  if not doc.meta.bibliography then return nil end

  local base_dir = quarto and quarto.doc and quarto.doc.input_file
    and pandoc.path.directory(quarto.doc.input_file)
  resolve_meta_paths(doc.meta, base_dir)

  local json_in = pandoc.json.encode(doc)
  local ok, json_out = pcall(pandoc.pipe, 'pandoc', { '-f', 'json', '-t', 'json', '--citeproc' }, json_in)
  if not ok then return nil end
  local ok2, resolved = pcall(pandoc.read, json_out, 'json')
  if not ok2 then return nil end

  return resolved:walk({ Div = refs_to_definition_list })
end
