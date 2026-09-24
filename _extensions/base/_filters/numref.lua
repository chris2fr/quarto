-- Resolves {{< numref id >}} links to the number of {{< num id=id >}}.
local numbers = {}

function Pandoc(doc)
  doc:walk({
    Span = function(span)
      if span.classes:includes('num') and span.identifier ~= '' then
        numbers[span.identifier] = pandoc.utils.stringify(span.content)
      end
    end,
  })
  return doc:walk({
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
end
