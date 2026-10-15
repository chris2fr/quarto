local count = 0

-- {{< num >}}          plain automatic counter
-- {{< num id=cond-a >}} counter that can be cited with {{< numref cond-a >}}
return {
  ['num'] = function(args, kwargs, meta)
    count = count + 1
    local n = pandoc.Str(tostring(count))
    local id = pandoc.utils.stringify(kwargs['id'] or '')
    if id == '' then
      return n
    end
    return pandoc.Span({ n }, pandoc.Attr(id, { 'num' }))
  end,
}
