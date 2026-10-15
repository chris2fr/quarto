-- Keep persistent state in the global table so duplicate loads / multiple passes won't reassign numbers
local state = _G._quarto_num_state or { count = 0, ids = {} }
_G._quarto_num_state = state

return {
  ['num'] = function(args, kwargs, meta)
    local id = pandoc.utils.stringify(kwargs['id'] or '')

    if id ~= '' then
      -- if this id was already assigned, return the same number without incrementing
      if state.ids[id] then
        local n = pandoc.Str(tostring(state.ids[id]))
        return pandoc.Span({ n }, pandoc.Attr(id, { 'num' }))
      end

      -- otherwise assign a new number for this id
      state.count = state.count + 1
      state.ids[id] = state.count
      local n = pandoc.Str(tostring(state.count))
      return pandoc.Span({ n }, pandoc.Attr(id, { 'num' }))
    else
      -- no id: return the next number (increments each invocation)
      state.count = state.count + 1
      local n = pandoc.Str(tostring(state.count))
      return n
    end
  end,
}
