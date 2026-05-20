local required_meta = { 'title', 'author', 'lang', 'date' }
local optional_meta = { 'place', 'organization', 'ref' }
local required_divs = { 'participants', 'body' }

local seen = {}

function Div(el)
  for _, class in ipairs(required_divs) do
    if el.classes:includes(class) then
      seen[class] = true
    end
  end
end

function Pandoc(doc)
  local known_meta = {}
  for _, k in ipairs(required_meta) do known_meta[k] = true end
  for _, k in ipairs(optional_meta) do known_meta[k] = true end

  local blocks = {}
  for _, block in ipairs(doc.blocks) do
    if block.t == 'Div' then
      table.insert(blocks, block)
    end
  end
  doc.blocks = blocks

  local missing = {}
  for _, key in ipairs(required_meta) do
    if not doc.meta[key] then
      table.insert(missing, key)
    end
  end
  if #missing > 0 then
    error('Compte-rendu: missing required metadata: ' .. table.concat(missing, ', '))
  end

  for key, _ in pairs(doc.meta) do
    if key:match('^%l[%l%-]*$') and not known_meta[key] then
      io.stderr:write('WARNING [compte-rendu]: unrecognized metadata key: ' .. key .. '\n')
    end
  end

  for _, class in ipairs(required_divs) do
    if not seen[class] then
      table.insert(missing, '::: ' .. class .. ' :::')
    end
  end
  if #missing > 0 then
    error('Compte-rendu: missing required div(s):\n  ' .. table.concat(missing, '\n  '))
  end

  return doc
end
