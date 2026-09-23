-- environment.lua
-- Copyright (C) 2020 by RStudio, PBC

local classEnvironments = pandoc.MetaMap({})
local classCommands = pandoc.MetaMap({})

-- helper that identifies arrays
local function tisarray(t)
  local i = 0
  for _ in pairs(t) do
    i = i + 1
    if t[i] == nil then return false end
  end
  return true
end

-- reads the environments
local function readEnvironments(meta)
  local env = meta['environments']
  if env ~= nil then
    if tisarray(env) then
      -- read an array of strings
      for i, v in ipairs(env) do
        local value = pandoc.utils.stringify(v)
        classEnvironments[value] = value
      end
    else
      -- read key value pairs
      for k, v in pairs(env) do
        local key = pandoc.utils.stringify(k)
        local value = pandoc.utils.stringify(v)
        classEnvironments[key] = value
      end
    end
  end
end

local function readCommands(meta)
  local env = meta['commands']
  if env ~= nil then
    if tisarray(env) then
      -- read an array of strings
      for i, v in ipairs(env) do
        local value = pandoc.utils.stringify(v)
        classCommands[value] = value
      end
    else
      -- read key value pairs
      for k, v in pairs(env) do
        local key = pandoc.utils.stringify(k)
        local value = pandoc.utils.stringify(v)
        classCommands[key] = value
      end
    end
  end
end

local function readEnvsAndCommands(meta)
  readEnvironments(meta)
  readCommands(meta)
end

-- use the environments from metadata to
-- emit a custom environment for latex
local function writeEnvironments(divEl)
  if quarto.doc.is_format("latex") then
    for k, v in pairs(classEnvironments) do
      if divEl.attr.classes:includes(k) then
        -- process this into a latex environment
        local beginEnv = '\\begin' .. '{' .. v .. '}'
        local endEnv = '\n\\end{' .. v .. '}'
        
        -- check if custom options or arguments are present
        -- and add them to the environment accordingly
        local opts = divEl.attr.attributes['options']
        if opts then
          beginEnv = beginEnv .. '[' .. opts .. ']'
        end

        local args = divEl.attr.attributes['arguments']
        if args then
          beginEnv = beginEnv .. '{' .. args .. '}'
        end
        
        -- if the first and last div blocks are paragraphs then we can
        -- bring the environment begin/end closer to the content
        if #divEl.content > 0 and divEl.content[1].t == "Para" and divEl.content[#divEl.content].t == "Para" then
          table.insert(divEl.content[1].content, 1, pandoc.RawInline('tex', beginEnv .. "\n"))
          table.insert(divEl.content[#divEl.content].content, pandoc.RawInline('tex', "\n" .. endEnv))
        else
          table.insert(divEl.content, 1, pandoc.RawBlock('tex', beginEnv))
          table.insert(divEl.content, pandoc.RawBlock('tex', endEnv))
        end
        return divEl
      end
    end
  end
end

-- Same as writeEnvironments, but for inline Spans rather than block Divs.
-- A Div is always its own block — Pandoc's LaTeX writer separates adjacent
-- blocks with a blank line, which forces a paragraph break (and, e.g.,
-- stacks two side-by-side `::: {.minipage} :::` divs vertically instead of
-- placing them next to each other). A Span stays inline within the
-- surrounding paragraph, so two adjacent minipage spans (with plain text or
-- `\hfill` between them) end up on the same LaTeX line as intended.
local function writeSpanEnvironments(spanEl)
  if quarto.doc.is_format("latex") then
    for k, v in pairs(classEnvironments) do
      if spanEl.attr.classes:includes(k) then
        local beginEnv = '\\begin' .. '{' .. v .. '}'
        local endEnv = '\\end{' .. v .. '}'

        local opts = spanEl.attr.attributes['options']
        if opts then
          beginEnv = beginEnv .. '[' .. opts .. ']'
        end

        local args = spanEl.attr.attributes['arguments']
        if args then
          beginEnv = beginEnv .. '{' .. args .. '}'
        end

        local result = spanEl.content
        table.insert(result, 1, pandoc.RawInline('tex', beginEnv))
        table.insert(result, pandoc.RawInline('tex', endEnv))
        return result
      end
    end
  end
end

local function buildCommandArgs(opts, format)
  local function wrap(o) 
    return string.format(format, o)
  end 
  local t = pandoc.List()
  for str in string.gmatch(opts, "([^"..",".."]+)") do
    t:insert(str)
  end
  return table.concat(t:map(wrap), "")
end

-- use the environments from metadata to
-- emit a custom environment for latex
local function writeCommands(spanEl)
  if quarto.doc.is_format("latex") then
    for k, v in pairs(classCommands) do
      if spanEl.attr.classes:includes(k) then

        -- resolve the begin command
        local beginCommand = '\\' .. pandoc.utils.stringify(v)
        local opts = spanEl.attr.attributes['options']
        local args = spanEl.attr.attributes['arguments']
        if opts then
          beginCommand = beginCommand .. buildCommandArgs(opts, "[%s]")
        end
        if args then
          beginCommand = beginCommand .. buildCommandArgs(args, "{%s}")
        end

        local beginCommandRaw = pandoc.RawInline('latex', beginCommand .. '{')

        -- the end command
        local endCommandRaw = pandoc.RawInline('latex', '}')

        -- attach the raw inlines to the span contents
        local result = spanEl.content
        table.insert(result, 1, beginCommandRaw)
        table.insert(result, endCommandRaw)

        return result
      end
    end
  end
end

-- Run in three passes: first process metadata, then Divs/Spans for
-- `commands:`, then Spans again for `environments:` — a Span already
-- rewritten by writeCommands is no longer a Span (it's raw inlines), so it
-- won't be revisited here; one still holding an `environments:`-listed
-- class falls through to writeSpanEnvironments.
return {
  { Meta = readEnvsAndCommands },
  { Div = writeEnvironments, Span = writeCommands },
  { Span = writeSpanEnvironments }
}
