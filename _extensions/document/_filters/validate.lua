local required_meta = { 'title', 'lang' }
local optional_meta = { 'author', 'date', 'subtitle', 'ref', 'organization', 'place' }

function Pandoc(doc)
  local known_meta = {}
  for _, k in ipairs(required_meta) do known_meta[k] = true end
  for _, k in ipairs(optional_meta) do known_meta[k] = true end

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
