-- A manually-assigned `shorthand = {...}` field on a bibliography entry
-- drives its CSL citation-label (base/resources/biblio.csl's citation and
-- bibliography label, applied to PDF, HTML and md — the formats that load
-- that CSL, via each extension's own `csl:` key) instead of citeproc's
-- auto-generated author+year one. Entries with no shorthand field are
-- untouched — still auto-generated as before.
--
-- BibTeX has no field named "shorthand", or any passthrough for arbitrary
-- custom fields: pandoc's own bibtex reader silently drops anything it
-- doesn't recognize (verified against shorthand/label/key/eprint/... — none
-- survive). citeproc reads `bibliography:` itself and never exposes the
-- parsed entries to filters otherwise, so there's no AST-level hook for
-- this. Instead: convert the whole .bib to CSL-JSON with the same pandoc
-- binary already rendering this document, separately scan the raw .bib text
-- for each entry's own `shorthand = {...}` (a deliberately small,
-- non-general scan — not full BibTeX parsing, just enough to pull one
-- field), merge the two, and point `bibliography:` at the merged JSON
-- instead of the original .bib so citeproc reads the augmented data.
--
-- Runs at the default (pre-quarto) filter position — same as every other
-- filter in this extension that doesn't set `at:` — since citeproc itself
-- runs later, between pre-quarto and post-quarto.

local function read_file(path)
  local f = io.open(path, 'r')
  if not f then return nil end
  local content = f:read('a')
  f:close()
  return content
end

-- Slices the file into one chunk per @type{id, ... entry (from one
-- @-header to the next, or EOF) and pulls `shorthand = {...}` / `= "..."`
-- out of each chunk — robust to closing-brace placement, which a
-- \n}-anchored pattern isn't (e.g. a field value itself containing "}\n").
local function extract_shorthands(bibtext)
  local starts = {}
  for pos, id in bibtext:gmatch('()@%a+%s*{%s*([%w_%-:.]+)%s*,') do
    table.insert(starts, { pos = pos, id = id })
  end
  local shorthands = {}
  for i, s in ipairs(starts) do
    local endpos = (starts[i + 1] and starts[i + 1].pos - 1) or #bibtext
    local body = bibtext:sub(s.pos, endpos)
    local value = body:match('shorthand%s*=%s*{(.-)}') or body:match('shorthand%s*=%s*"(.-)"')
    if value then shorthands[s.id] = value end
  end
  return shorthands
end

-- Tries each candidate base directory in turn and returns the content of
-- the first one where `path` actually resolves to a readable file. Relative
-- metadata paths like `bibliography:` are conventionally resolved against
-- the document's own directory: quarto.doc.input_file is the real source
-- path and the right one for that. quarto.project.directory (project root)
-- is a fallback for whatever it doesn't cover; PANDOC_STATE.input_files[1]
-- is quarto's *staged* copy of the source file, in a temp session directory
-- that never contains sibling resources like a .bib — kept as a last
-- resort (e.g. quarto.doc unavailable) but not relied on.
local function read_relative(path)
  if pandoc.path.is_absolute(path) then
    return read_file(path)
  end
  local candidates = {}
  if quarto and quarto.doc and quarto.doc.input_file then
    table.insert(candidates, pandoc.path.directory(quarto.doc.input_file))
  end
  if quarto and quarto.project and quarto.project.directory and quarto.project.directory ~= '' then
    table.insert(candidates, quarto.project.directory)
  end
  if PANDOC_STATE and PANDOC_STATE.input_files and #PANDOC_STATE.input_files > 0 then
    table.insert(candidates, pandoc.path.directory(PANDOC_STATE.input_files[1]))
  end
  for _, dir in ipairs(candidates) do
    local content = read_file(pandoc.path.join({ dir, path }))
    if content then return content end
  end
  return nil
end

-- CSL's <bibliography><sort> compares each key's *rendered text*, even for
-- variables the spec calls "numeric" (verified: sorting by the standard
-- `number` variable is still lexicographic in pandoc's citeproc) — so a
-- plain shorthand sort would put "10" before "2". Zero-padded to the same
-- width, string order and numeric order coincide. Written to the unused
-- `version` variable (not read anywhere in biblio.csl's own macros, unlike
-- `number`, which already prints `[N]` in the bibliography body) purely as
-- a sort key — `citation-label` keeps the plain, unpadded value for display.
local function widest(shorthands)
  local width = 0
  for _, v in pairs(shorthands) do
    if v:match('^%d+$') then width = math.max(width, #v) end
  end
  return width
end

-- Returns the path to an augmented CSL-JSON file, or nil if augmentation
-- wasn't possible/needed (no shorthand fields, file unreadable, pandoc.pipe
-- failed, ...) — caller falls back to the original path untouched.
local function augment(path)
  local bibtext = read_relative(path)
  if not bibtext then return nil end

  local shorthands = extract_shorthands(bibtext)
  if next(shorthands) == nil then return nil end
  local width = widest(shorthands)

  local ok, json_text = pcall(pandoc.pipe, 'pandoc', { '-f', 'bibtex', '-t', 'csljson' }, bibtext)
  if not ok then return nil end
  local ok2, entries = pcall(pandoc.json.decode, json_text)
  if not ok2 or type(entries) ~= 'table' then return nil end

  for _, entry in ipairs(entries) do
    local sh = shorthands[entry.id]
    if sh then
      entry['citation-label'] = sh
      entry['version'] = sh:match('^%d+$') and string.rep('0', width - #sh) .. sh or sh
    end
  end

  local tmp = os.tmpname()
  os.remove(tmp)
  tmp = tmp .. '.json'
  local out = io.open(tmp, 'w')
  if not out then return nil end
  out:write(pandoc.json.encode(entries))
  out:close()
  return tmp
end

function Meta(m)
  if not (FORMAT:match('latex') or FORMAT:match('html') or FORMAT:match('markdown')) then return nil end
  if not m.bibliography then return nil end

  local paths = {}
  if m.bibliography.t == 'MetaList' then
    for _, v in ipairs(m.bibliography) do table.insert(paths, pandoc.utils.stringify(v)) end
  else
    table.insert(paths, pandoc.utils.stringify(m.bibliography))
  end

  local changed = false
  local new_paths = {}
  for _, p in ipairs(paths) do
    local augmented = p:match('%.bib$') and augment(p)
    if augmented then
      table.insert(new_paths, augmented)
      changed = true
    else
      table.insert(new_paths, p)
    end
  end

  if not changed then return nil end
  m.bibliography = pandoc.MetaList(new_paths)
  return m
end
