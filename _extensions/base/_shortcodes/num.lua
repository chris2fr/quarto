-- {{< num >}}          plain automatic counter
-- {{< num id=cond-a >}} counter that can be cited with {{< numref cond-a >}}
-- The shortcode only emits a placeholder; the number itself is assigned in
-- document order by _filters/numref.lua, so it always starts at 1.
return {
  ['num'] = function(args, kwargs, meta)
    local id = pandoc.utils.stringify(kwargs['id'] or '')
    return pandoc.Span({ pandoc.Str('?') }, pandoc.Attr(id, { 'num' }))
  end,
}
