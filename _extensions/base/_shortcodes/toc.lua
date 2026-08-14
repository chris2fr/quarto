-- {{< toc >}} — placed wherever a document wants its table of contents.
-- Shortcodes are expanded before ../_filters/page.lua's own Pandoc(doc) pass
-- runs, so this can't see the rest of the document yet (headers before or
-- after it). It just drops an empty marker Div; ../_filters/toc.lua replaces
-- every such marker once the full document (and its headers) exist.
--
-- Optional `level` kwarg (e.g. {{< toc level=2 >}}) caps how deep the TOC
-- goes — 1 (h1 only) through 5 (h1-h5, the deepest LaTeX has a sectioning
-- command for). Carried on the marker Div as an attribute since the filter
-- runs in a separate pass with no access to the shortcode's own arguments.
return {
  ['toc'] = function(args, kwargs, meta)
    local attributes = {}
    local level = kwargs.level and pandoc.utils.stringify(kwargs.level)
    if level and level:match('^[1-5]$') then
      attributes.level = level
    end
    return pandoc.Div({}, pandoc.Attr('', { 'quarto-lettre-toc' }, attributes))
  end
}
