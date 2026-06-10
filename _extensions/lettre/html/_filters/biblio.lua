function Div(el)
  if el.identifier == 'refs' then
    return pandoc.Div({el}, pandoc.Attr('bibliography-wrapper', {'bibliography-wrapper'}))
  end
end
