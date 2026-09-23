-- Bundled-font lookup shared by page.lua (brand/metadata fonts for html and
-- latex) and html/web/_filters/webhtml.lua. Loaded with dofile().
-- ── Bundled fonts ───────────────────────────────────────────────────────────
-- A family named by the brand/metadata is first looked for as font files
-- shipped with the project, so it needn't be installed on the machine
-- rendering the document: <root>/fonts/<slug>/, <root>/_parts/fonts/<slug>/
-- or <root>/_parts/<anything>/fonts/<slug>/, where <root> is the document's
-- directory, its ancestors or the project root and <slug> is the lowercased, dash-separated
-- family name ("Fengardo Neue" -> fengardo-neue). Files are classified by
-- name: "italic"/"oblique" -> italic, "bold"/"black"/"heavy" -> bold, "medium"
-- -> weight 500 (CSS only; LaTeX has no slot for it); other weights (light,
-- semibold, ...) are ignored. Returns nil if none found.
local M = {}

local FONT_EXTS = { otf = true, ttf = true, woff2 = true, woff = true }

local function font_slug(family)
  local slug = family:lower():gsub('[^%w]+', '-')
  slug = slug:gsub('^%-+', ''):gsub('%-+$', '')
  return slug
end

local function list_dir(dir)
  local ok, entries = pcall(pandoc.system.list_directory, dir)
  return ok and entries or nil
end

local function find_font_dirs(family)
  local slug = font_slug(family)
  local roots = {}
  if quarto.doc and quarto.doc.input_file and quarto.doc.input_file ~= '' then
    -- The document's directory and its ancestors (a few levels), so a
    -- document in a subfolder still finds the project-level _parts/.
    local dir = pandoc.path.directory(quarto.doc.input_file)
    for _ = 1, 5 do
      table.insert(roots, dir)
      local parent = pandoc.path.directory(dir)
      if parent == dir or parent == '' then break end
      dir = parent
    end
  end
  if quarto.project and quarto.project.directory then
    table.insert(roots, quarto.project.directory)
  end

  local found, seen_dirs = {}, {}
  local function try(dir)
    local abs = dir:sub(1, 1) == '/' and dir
             or pandoc.path.join({ pandoc.system.get_working_directory(), dir })
    if not seen_dirs[abs] and list_dir(abs) then
      seen_dirs[abs] = true
      table.insert(found, abs)
    end
  end
  for _, root in ipairs(roots) do
    try(pandoc.path.join({ root, 'fonts', slug }))
    try(pandoc.path.join({ root, '_parts', 'fonts', slug }))
    for _, sub in ipairs(list_dir(pandoc.path.join({ root, '_parts' })) or {}) do
      try(pandoc.path.join({ root, '_parts', sub, 'fonts', slug }))
    end
  end
  return found
end

-- Returns { dir = <absolute dir>, faces = { ext -> { upright/italic/bold/
-- bolditalic -> basename-without-extension } } } for the first directory
-- holding usable files, or nil.
function M.find_local_font(family)
  for _, dir in ipairs(find_font_dirs(family)) do
    local faces = {}
    for _, entry in ipairs(list_dir(dir) or {}) do
      local base, ext = entry:match('^(.+)%.(%w+)$')
      ext = ext and ext:lower()
      if base and FONT_EXTS[ext] then
        local low = base:lower()
        if not (low:find('light') or low:find('thin')
             or low:find('semi') or low:find('extra')) then
          local italic = low:find('italic') or low:find('oblique')
          local bold = low:find('bold') or low:find('black') or low:find('heavy')
          local medium = low:find('medium')
          local slot = (bold and italic and 'bolditalic') or (bold and 'bold')
                    or (medium and not italic and 'medium') or (medium and 'mediumitalic')
                    or (italic and 'italic') or 'upright'
          faces[ext] = faces[ext] or {}
          local cur = faces[ext][slot]
          if not cur or #base < #cur or (#base == #cur and base < cur) then
            faces[ext][slot] = base
          end
        end
      end
    end
    for _, ext in ipairs({ 'otf', 'ttf' }) do
      if faces[ext] and faces[ext].upright then
        return { dir = dir, faces = faces, family = family }
      end
    end
  end
  return nil
end


local WEIGHTS = {
  upright = { 400, 'normal' }, italic = { 400, 'italic' },
  medium = { 500, 'normal' }, mediumitalic = { 500, 'italic' },
  bold = { 700, 'normal' }, bolditalic = { 700, 'italic' },
}
local FORMATS = { woff2 = 'woff2', woff = 'woff', otf = 'opentype', ttf = 'truetype' }

-- @font-face rules for a bundled family (see find_local_font), one per style
-- in its best web format. `url_prefix` is prepended to each file name, and
-- each file is appended to `resources` ({ name, path }) for add_html_dependency.
function M.font_face_css(family, lf, url_prefix, resources)
  local css = {}
  for _, slot in ipairs({ 'upright', 'italic', 'medium', 'mediumitalic', 'bold', 'bolditalic' }) do
    for _, ext in ipairs({ 'woff2', 'woff', 'otf', 'ttf' }) do
      local base = lf.faces[ext] and lf.faces[ext][slot]
      if base then
        local file = base .. '.' .. ext
        table.insert(resources, { name = url_prefix .. file, path = pandoc.path.join({ lf.dir, file }) })
        table.insert(css, string.format(
          '@font-face { font-family: "%s"; font-weight: %d; font-style: %s; font-display: swap; src: url("%s") format("%s"); }',
          family, WEIGHTS[slot][1], WEIGHTS[slot][2], url_prefix .. file, FORMATS[ext]))
        break
      end
    end
  end
  return css
end

return M
