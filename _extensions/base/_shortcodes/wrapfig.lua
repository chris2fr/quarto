-- {{< wrapfig src=./images/x.jpg caption="Légende" width=35 align=l >}}
--
-- A figure the following text wraps around. PDF: `wrapfigure` (wrapfig
-- package); HTML: a floated <figure>; any other format: a plain pandoc
-- Figure (no wrapping, but the image and caption survive).
--
--   src      image path (required)
--   caption  caption text (default: none, and no \caption is emitted)
--   width    wrapfigure width as a percentage of \textwidth (default 35)
--   align    l or r (also i/o for inner/outer, PDF only; HTML maps i->l,
--            o->r) (default l)
--
-- The image itself is 2 points narrower than the wrapfigure box
-- (width - 2 %), as in the hand-written LaTeX it replaces.
--
-- Put the shortcode on its own line right before the paragraph that should
-- wrap: wrapfig only works if it starts at a paragraph boundary.

local function kwarg(kwargs, key, default)
  local v = kwargs[key] and pandoc.utils.stringify(kwargs[key]) or ''
  if v == '' then return default end
  return v
end

local function latex_escape(s)
  return (pandoc.write(pandoc.Pandoc({pandoc.Plain({pandoc.Str(s)})}), 'latex'):gsub('%s+$', ''))
end

local function fmt(n)
  return (string.format('%.3f', n):gsub('0+$', ''):gsub('%.$', ''))
end

return {
  ['wrapfig'] = function(args, kwargs, meta)
    local src = kwarg(kwargs, 'src', '')
    if src == '' then
      quarto.log.warning('wrapfig: missing src')
      return pandoc.Null()
    end
    local caption = kwarg(kwargs, 'caption', '')
    local width = tonumber(kwarg(kwargs, 'width', '35')) or 35
    local align = kwarg(kwargs, 'align', 'l')
    local inner = width - 2

    if quarto.doc.is_format('latex') then
      quarto.doc.use_latex_package('wrapfig')
      local tex = '\\begin{wrapfigure}{' .. align .. '}{' .. fmt(width / 100) .. '\\textwidth}\n'
        .. '\\centering\n'
        .. '\\includegraphics[width=' .. fmt(inner / 100) .. '\\textwidth]{' .. src .. '}\n'
      if caption ~= '' then
        tex = tex .. '\\caption{' .. latex_escape(caption) .. '}\n'
      end
      return pandoc.RawBlock('tex', tex .. '\\end{wrapfigure}')
    end

    if quarto.doc.is_format('html') then
      local side = (align == 'r' or align == 'o' or align == 'R' or align == 'O') and 'right' or 'left'
      local margin = side == 'left' and '0 1em 0.5em 0' or '0 0 0.5em 1em'
      local html = '<figure class="wrapfig" style="float:' .. side .. ';width:' .. fmt(width)
        .. '%;margin:' .. margin .. ';">'
        .. '<img src="' .. src .. '" style="width:' .. fmt(inner / width * 100) .. '%;" alt="' 
        .. pandoc.utils.stringify(pandoc.Str(caption)):gsub('"', '&quot;') .. '">'
      if caption ~= '' then
        html = html .. '<figcaption>' .. pandoc.write(
          pandoc.Pandoc({pandoc.Plain({pandoc.Str(caption)})}), 'html'):gsub('%s+$', '') .. '</figcaption>'
      end
      return pandoc.RawBlock('html', html .. '</figure>')
    end

    -- A lone image in a Para becomes a captioned figure (implicit figure);
    -- returning a Figure block makes quarto's shortcode handling choke.
    local caption_inlines = caption ~= '' and {pandoc.Str(caption)} or {}
    return pandoc.Para({pandoc.Image(caption_inlines, src)})
  end,
}
