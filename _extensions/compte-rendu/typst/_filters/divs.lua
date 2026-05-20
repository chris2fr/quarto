local function to_typst(blocks)
  return pandoc.write(pandoc.Pandoc(blocks), 'typst'):gsub('\n$', '')
end

local function s(v)
  return v and pandoc.utils.stringify(v) or ''
end

local function section_heading(label)
  return '#text(weight: "bold", font: ("Liberation Sans", "Helvetica", "Arial", "sans-serif"), size: 11pt)['
         .. label .. ']\n'
         .. '#line(length: 100%, stroke: 0.5pt + luma(140))\n'
         .. '#v(0.3em)\n'
end

local handlers = {
  participants = function(c, _)
    return section_heading('Participants') .. to_typst(c) .. '\n#v(0.8em)'
  end,

  agenda = function(c, _)
    return section_heading('Ordre du jour') .. to_typst(c) .. '\n#v(0.8em)'
  end,

  body = function(c, _)
    return to_typst(c) .. '\n#v(0.5em)'
  end,

  decisions = function(c, _)
    return section_heading('Décisions') ..
           '#rect(fill: luma(245), stroke: (left: 3pt + luma(150)), inset: (left: 10pt, right: 8pt, top: 6pt, bottom: 6pt), width: 100%, radius: (right: 3pt))[\n' ..
           to_typst(c) .. '\n]\n#v(0.8em)'
  end,

  actions = function(c, _)
    return section_heading('Actions') .. to_typst(c) .. '\n#v(0.8em)'
  end,

  ['next-meeting'] = function(c, _)
    return section_heading('Prochaine réunion') .. to_typst(c) .. '\n#v(0.8em)'
  end,

  approval = function(c, _)
    return '#v(2em)\n#align(right)[#block(width: 10cm)[\n' ..
           to_typst(c) .. '\n]]\n'
  end,
}

function Pandoc(doc)
  local meta = {
    author       = s(doc.meta.author),
    organization = s(doc.meta.organization),
    place        = s(doc.meta.place),
    title        = s(doc.meta.title),
    ref          = s(doc.meta.ref),
    date         = s(doc.meta.date),
  }

  -- Title block injected at the start
  local title_block = ''
  if meta.organization ~= '' then
    title_block = title_block ..
      '#align(center)[#text(size: 9pt, fill: luma(100))[#upper[' .. meta.organization .. ']]]\n#v(0.3em)\n'
  end
  title_block = title_block ..
    '#align(center)[#text(size: 18pt, weight: "bold")[Compte-rendu de réunion]]\n' ..
    '#v(0.3em)\n' ..
    '#align(center)[#text(size: 13pt)[' .. meta.title .. ']]\n' ..
    '#v(0.2em)\n' ..
    '#align(center)[#text(size: 10pt, style: "italic")['
  title_block = title_block .. meta.date
  if meta.place ~= '' then
    title_block = title_block .. ' --- ' .. meta.place
  end
  title_block = title_block .. ']]\n'
  if meta.ref ~= '' then
    title_block = title_block ..
      '#v(0.1em)\n#align(center)[#text(size: 9pt)[Réf. : ' .. meta.ref .. ']]\n'
  end
  title_block = title_block .. '#v(0.5em)\n#line(length: 100%, stroke: 1pt)\n#v(0.8em)\n'

  local new_blocks = { pandoc.RawBlock('typst', title_block) }

  for _, block in ipairs(doc.blocks) do
    local converted = false
    if block.t == 'Div' then
      for class, handler in pairs(handlers) do
        if block.classes:includes(class) then
          table.insert(new_blocks,
            pandoc.RawBlock('typst', handler(block.content, meta)))
          converted = true
          break
        end
      end
    end
    if not converted then
      table.insert(new_blocks, block)
    end
  end

  doc.blocks = new_blocks
  return doc
end
