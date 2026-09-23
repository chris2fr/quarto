-- Strict lesgrandsvoisins.com look for the *-web-html formats: the site's own
-- stylesheet (css/site.css, vendored verbatim), delivered as an HTML
-- dependency so it's copied next to the rendered page. Its @font-face rules
-- are the only thing replaced: the fonts live once, in the project's
-- _parts/<brand>/fonts/<family>/ (see bundled_fonts.lua), and each family
-- the stylesheet declares is re-declared from those files. A family with no
-- bundled files keeps the site's own rule (which then falls back to the
-- font stack, since the site's font files aren't shipped here).
-- css/webdoc.css adds the few document-only pieces (letter blocks, title
-- block) the site has no equivalent for, in the site's own tokens.
local here = pandoc.path.directory(PANDOC_SCRIPT_FILE)
local web = pandoc.path.join({ here, '..' })
local bundled_fonts = dofile(pandoc.path.join({ here, '..', '..', '..', '_filters', 'bundled_fonts.lua' }))

local function read(path)
  local fh = io.open(path, 'r')
  if not fh then return nil end
  local s = fh:read('a')
  fh:close()
  return s
end

function Pandoc(doc)
  if not FORMAT:match('html') then return end
  local site = read(pandoc.path.join({ web, 'css', 'site.css' }))
  local extra = read(pandoc.path.join({ web, 'css', 'webdoc.css' })) or ''
  if not site then
    quarto.log.warning('webhtml: css/site.css not found next to the filter')
    return
  end

  local resources, faces, replaced = {}, {}, {}
  -- Every family the site stylesheet declares...
  for family in site:gmatch('@font%-face%s*{[^}]-font%-family:%s*"([^"]+)"') do
    if replaced[family] == nil then
      local lf = bundled_fonts.find_local_font(family)
      replaced[family] = lf and true or false
      if lf then
        for _, rule in ipairs(bundled_fonts.font_face_css(family, lf, 'fonts/', resources)) do
          table.insert(faces, rule)
        end
      else
        quarto.log.warning('webhtml: no bundled files for font "' .. family
          .. '" (expected fonts/' .. family:lower():gsub('[^%w]+', '-') .. '/ under the project or its _parts/)')
      end
    end
  end
  -- ...whose bundled version replaces the site's own rule.
  site = site:gsub('@font%-face%s*(%b{})', function(body)
    local family = body:match('font%-family:%s*"([^"]+)"')
    if family and replaced[family] then return '' end
  end)

  local css_path = os.tmpname()
  local fh = io.open(css_path, 'w')
  fh:write(table.concat(faces, '\n'), '\n', site, '\n', extra)
  fh:close()

  quarto.doc.add_html_dependency({
    name = 'lettre-webhtml', version = '1.0.0',
    resources = resources,
    stylesheets = { { name = 'site.css', path = css_path } },
  })
  return doc
end
