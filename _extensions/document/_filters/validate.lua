local required_meta = { 'title', 'lang' }
local optional_meta = {
  'author', 'date', 'subtitle', 'ref', 'organization', 'place',
  'doc-date', 'doc-ref', 'doc-header', 'doc-footer',
}

-- Keys that show up in doc.meta by the time this filter runs (after
-- ../base/_filters/page.lua) without ever being typed by a document's own
-- author. Some are format defaults set by this extension's own
-- _extension.yml; some are computed/injected by page.lua itself (margins,
-- brand fonts); the rest are Quarto/Pandoc's own reserved or auto-injected
-- keys (author normalisation, i18n, template plumbing). A few — bibliography,
-- csl, tex-custom, margin-* — *can* also be set directly by an author, but
-- are listed here rather than in optional_meta above since they arrive
-- already merged in either case and a typo in them wouldn't be caught
-- either way. Kept separate from optional_meta so that list stays a true
-- reference of what a document author can type in front matter; extend this
-- one (not optional_meta) when a legitimate upstream key trips a
-- false-positive warning.
local upstream_meta = {
  -- document/_extension.yml format defaults
  'base-format', 'date-format', 'french-quotes', 'page-layout', 'theme',
  'papersize', 'lof', 'lot',
  -- page.lua (base filter): margin resolution, brand fonts, bibliography wiring
  'margin-inner', 'margin-outer', 'margin-top', 'margin-bottom',
  'margin-all', 'marginx', 'marginy',
  'header-includes', 'bibliography', 'csl', 'tex-custom', 'labels',
  'nocite', 'tab-stop',
  -- Quarto/Pandoc reserved or auto-injected
  'authors', 'by-author', 'language', 'toc-title', 'quarto-version',
  'include-before', 'include-after', 'fig-responsive', 'revealjs-plugins',
  'colorlinks', 'linkcolor', 'block-headings', 'biblio-config', 'document-css',
}

function Pandoc(doc)
  local known_meta = {}
  for _, k in ipairs(required_meta) do known_meta[k] = true end
  for _, k in ipairs(optional_meta) do known_meta[k] = true end
  for _, k in ipairs(upstream_meta) do known_meta[k] = true end

  local missing = {}
  for _, key in ipairs(required_meta) do
    if not doc.meta[key] then
      table.insert(missing, key)
    end
  end
  if #missing > 0 then
    error('Document: missing required metadata: ' .. table.concat(missing, ', '))
  end

  for key, _ in pairs(doc.meta) do
    if key:match('^%l[%l%-]*$') and not known_meta[key] then
      io.stderr:write('WARNING [document]: unrecognized metadata key: ' .. key .. '\n')
    end
  end

  return doc
end
