-- {{< toc >}} — placed wherever a document wants its table of contents.
-- Shortcodes are expanded before ../_filters/page.lua's own Pandoc(doc) pass
-- runs, so this can't see the rest of the document yet (headers before or
-- after it). It just drops an empty marker Div; page.lua's expand_toc()
-- replaces every such marker once the full document (and its headers) exist.
return {
  ['toc'] = function(args, kwargs, meta)
    return pandoc.Div({}, pandoc.Attr('', { 'quarto-lettre-toc' }))
  end
}
