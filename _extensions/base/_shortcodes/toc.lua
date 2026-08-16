-- {{< toc >}} / {{< lot >}} — placed wherever a document wants its table of
-- contents / list of tables. Shortcodes are expanded before
-- ../_filters/page.lua's own Pandoc(doc) pass runs, so this can't see the
-- rest of the document yet (headers/tables before or after it). Each just
-- drops an empty marker Div; ../_filters/toc.lua replaces every such marker
-- once the full document exists.
--
-- {{< toc >}}'s optional `level` kwarg (e.g. {{< toc level=2 >}}) caps how
-- deep the TOC goes — 1 (h1 only) through 5 (h1-h5, the deepest LaTeX has a
-- sectioning command for). Carried on the marker Div as an attribute since
-- the filter runs in a separate pass with no access to the shortcode's own
-- arguments.
--
-- {{< lot >}} lists tables that have a crossref id (`::: {#tbl-xxx
-- .list-table}` — this extensions' own table mechanism; see ../_filters/toc.lua
-- for why a plain pandoc table/figure with a `{#tbl-xxx}` caption attribute
-- can't be listed the same way). No `{{< lof >}}` (list of figures)
-- counterpart yet — figure ids aren't resolved this early in quarto's own
-- pipeline, unlike list-table's.
return {
  ['toc'] = function(args, kwargs, meta)
    local attributes = {}
    local level = kwargs.level and pandoc.utils.stringify(kwargs.level)
    if level and level:match('^[1-5]$') then
      attributes.level = level
    end
    return pandoc.Div({}, pandoc.Attr('', { 'quarto-lettre-toc' }, attributes))
  end,
  ['lot'] = function(args, kwargs, meta)
    return pandoc.Div({}, pandoc.Attr('', { 'quarto-lettre-lot' }))
  end,
}
