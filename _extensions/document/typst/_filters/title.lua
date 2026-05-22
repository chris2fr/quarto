local function s(v)
  return v and pandoc.utils.stringify(v) or ''
end

function Pandoc(doc)
  local meta = {
    title        = s(doc.meta.title),
    subtitle     = s(doc.meta.subtitle),
    author       = s(doc.meta.author),
    organization = s(doc.meta.organization),
    place        = s(doc.meta.place),
    date         = s(doc.meta.date),
    ref          = s(doc.meta.ref),
  }

  local t = ''

  if meta.organization ~= '' then
    t = t .. '#align(center)[#text(size: 9pt, fill: luma(100))[#upper[' .. meta.organization .. ']]]\n#v(0.3em)\n'
  end

  t = t .. '#align(center)[#text(size: 20pt, weight: "bold")[' .. meta.title .. ']]\n'

  if meta.subtitle ~= '' then
    t = t .. '#v(0.3em)\n#align(center)[#text(size: 14pt)[' .. meta.subtitle .. ']]\n'
  end

  if meta.author ~= '' then
    t = t .. '#v(0.2em)\n#align(center)[#text(size: 11pt)[' .. meta.author .. ']]\n'
  end

  if meta.date ~= '' then
    t = t .. '#v(0.2em)\n#align(center)[#text(size: 10pt, style: "italic")['
    t = t .. meta.date
    if meta.place ~= '' then t = t .. ' --- ' .. meta.place end
    t = t .. ']]\n'
  end

  if meta.ref ~= '' then
    t = t .. '#v(0.1em)\n#align(center)[#text(size: 9pt)[Réf. : ' .. meta.ref .. ']]\n'
  end

  t = t .. '#v(0.5em)\n#line(length: 100%, stroke: 1pt)\n#v(1em)\n'

  local new_blocks = { pandoc.RawBlock('typst', t) }
  for _, block in ipairs(doc.blocks) do
    table.insert(new_blocks, block)
  end
  doc.blocks = new_blocks
  return doc
end
