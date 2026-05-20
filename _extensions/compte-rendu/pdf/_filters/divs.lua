local env_for_class = {
  participants  = 'div-participants',
  agenda        = 'div-agenda',
  body          = 'div-body',
  decisions     = 'div-decisions',
  actions       = 'div-actions',
  ['next-meeting'] = 'div-next-meeting',
  approval      = 'div-approval',
}

local function wrap_div(el, env)
  table.insert(el.content, 1, pandoc.RawBlock('latex', '\\begin{' .. env .. '}'))
  table.insert(el.content, pandoc.RawBlock('latex', '\\end{' .. env .. '}'))
  return el
end

local function to_latex(blocks)
  return pandoc.write(pandoc.Pandoc(blocks), 'latex'):gsub('\n$', '')
end

function DefinitionList(el)
  local rows = {}
  for _, item in ipairs(el.content) do
    local term = to_latex({ pandoc.Plain(item[1]) })
    local def  = item[2] and item[2][1] and to_latex({ item[2][1][1] }) or ''
    table.insert(rows, term .. ' & ' .. def .. ' \\\\')
  end
  return pandoc.RawBlock('latex',
    '\\begin{longtable}{@{}p{0.35\\linewidth}p{0.65\\linewidth}@{}}\n' ..
    '\\toprule\n' ..
    table.concat(rows, '\n') .. '\n' ..
    '\\bottomrule\n' ..
    '\\end{longtable}')
end

function Div(el)
  for class, env in pairs(env_for_class) do
    if el.classes:includes(class) then
      return wrap_div(el, env)
    end
  end
end
