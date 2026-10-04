-- filtre-pieces.lua
--
-- Injecte les numéros de pièces dans les entrées bibliographiques
-- à partir d'un mapping `clé → numéro` défini dans le YAML frontmatter
-- du document, sous le champ `pieces`.
--
-- Utilisation dans le .qmd :
--
--   ---
--   filters:
--     - filtre-pieces.lua
--   pieces:
--     "2024-06-20-sipperecfr-0002": 10
--     "2023-12-14-sipperec-0001": 70
--     ...
--   ---
--
-- Le filtre s'exécute AVANT citeproc (comportement par défaut de Quarto).

function Meta(meta)
  if not meta.pieces then
    return meta
  end

  if not meta.references then
    io.stderr:write("[filtre-pieces] Aucune référence chargée.\n")
    return meta
  end

  local pieces = meta.pieces
  local n_injectes = 0
  local cles_absentes = {}

  for i, ref in ipairs(meta.references) do
    local cle = ref.id
    if cle then
      local num = pieces[cle]
      if num then
        ref.number = pandoc.MetaString(pandoc.utils.stringify(num))
        n_injectes = n_injectes + 1
      else
        table.insert(cles_absentes, cle)
      end
    end
  end

  io.stderr:write(string.format(
    "[filtre-pieces] %d numéro(s) injecté(s).\n", n_injectes
  ))

  if #cles_absentes > 0 then
    io.stderr:write(string.format(
      "[filtre-pieces] %d référence(s) sans numéro :\n", #cles_absentes
    ))
    for _, c in ipairs(cles_absentes) do
      io.stderr:write("  - " .. c .. "\n")
    end
  end

  return meta
end