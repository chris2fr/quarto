-- Resolves {{< numref id >}} links to the number of {{< num id=id >}}.
function Pandoc(doc)
  local numbers = {}
  -- Number every {{< num >}} in document order, starting at 1.
  local count = 0
  doc.blocks = doc.blocks:walk({
    Span = function(span)
      if not span.classes:includes('num') then return nil end
      count = count + 1
      local n = tostring(count)
      if span.identifier ~= '' and numbers[span.identifier] == nil then
        numbers[span.identifier] = n
      end
      span.content = { pandoc.Str(n) }
      return span
    end,
  })
  doc.blocks = doc.blocks:walk({
    Link = function(link)
      if not link.classes:includes('numref') then return nil end
      local id = link.target:gsub('^#', '')
      local n = numbers[id]
      if not n then
        io.stderr:write('[numref] unknown identifier: ' .. id .. '\n')
        n = '?'
      end
      link.content = { pandoc.Str(n) }
      return link
    end,
  })
  return doc
end
