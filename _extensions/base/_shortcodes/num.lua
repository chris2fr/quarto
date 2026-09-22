local count = 0

return {
  ['num'] = function(args, kwargs, meta)
    count = count + 1
    return pandoc.Str(tostring(count))
  end,
}