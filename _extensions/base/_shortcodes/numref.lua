-- {{< numref cond-a >}} link to the number given by {{< num id=cond-a >}}.
-- The number is filled in by _filters/numref.lua, so forward references work.
return {
  ['numref'] = function(args, kwargs, meta)
    local id = pandoc.utils.stringify(args[1] or kwargs['id'] or '')
    if id == '' then
      io.stderr:write('[numref] missing identifier\n')
      return pandoc.Str('?')
    end
    return pandoc.Link({ pandoc.Str('?') }, '#' .. id, '', pandoc.Attr('', { 'numref' }))
  end,
}
