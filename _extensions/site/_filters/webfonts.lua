-- @font-face rules for the site's fonts, from the project's bundled files
-- (_parts/<brand>/fonts/<family>/, see base/_filters/bundled_fonts.lua), as
-- an HTML dependency. Families come from the `webfonts` metadata list.
local here = pandoc.path.directory(PANDOC_SCRIPT_FILE)
local bundled_fonts = dofile(pandoc.path.join({ here, '..', '..', 'base', '_filters', 'bundled_fonts.lua' }))

local DEFAULT_FAMILIES = { 'Fengardo Neue', 'Lack', 'Fira Sans' }

function Pandoc(doc)
  if not FORMAT:match('html') then return end
  local families = {}
  if doc.meta.webfonts then
    for _, f in ipairs(doc.meta.webfonts) do table.insert(families, pandoc.utils.stringify(f)) end
  else
    families = DEFAULT_FAMILIES
  end

  local resources, faces = {}, {}
  for _, family in ipairs(families) do
    local lf = bundled_fonts.find_local_font(family)
    if lf then
      for _, rule in ipairs(bundled_fonts.font_face_css(family, lf, 'fonts/', resources)) do
        table.insert(faces, rule)
      end
    else
      quarto.log.warning('site: no bundled files for font "' .. family .. '"')
    end
  end
  if #faces == 0 then return end

  local css_path = os.tmpname()
  local fh = io.open(css_path, 'w')
  fh:write(table.concat(faces, '\n'), '\n')
  fh:close()
  quarto.doc.add_html_dependency({
    name = 'site-fonts', version = '1.0.0',
    resources = resources,
    stylesheets = { { name = 'fonts.css', path = css_path } },
  })
  return doc
end
