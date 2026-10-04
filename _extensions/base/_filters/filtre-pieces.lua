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
--     2024-06-20-sipperecfr-0002: 10
--     2023-12-14-sipperec-0001: 70
--     ...
--   ---
--
-- Le filtre s'exécute AVANT citeproc (comportement par défaut de Quarto).
-- Il modifie meta.references en place.

function Meta(meta)
  -- Vérifier la présence du mapping
  if not meta.pieces then
    return meta
  end

  local pieces = meta.pieces

  -- Vérifier la présence des références chargées
  if not meta.references then
    return meta
  end

  -- Parcourir les références et injecter les numéros
  local n_injectes = 0
  local n_manquants = 0

  for i, ref in ipairs(meta.references) do
    local cle = ref.id
    if cle then
      local num = pieces[cle]
      if num then
        -- Écrire le numéro comme MetaString
        ref.number = pandoc.MetaString(pandoc.utils.stringify(num))
        n_injectes = n_injectes + 1
      else
        n_manquants = n_manquants + 1
      end
    end
  end

  -- Trace pour vérification (visible avec quarto render --verbose)
  if n_manquants > 0 then
    io.stderr:write(string.format(
      "[filtre-pieces] %d numéro(s) injecté(s), %d référence(s) sans numéro.\n",
      n_injectes, n_manquants
    ))
  else
    io.stderr:write(string.format(
      "[filtre-pieces] %d numéro(s) injecté(s).\n", n_injectes
    ))
  end

  return meta
end