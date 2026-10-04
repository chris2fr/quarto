-- filtre-pieces.lua
--
-- Injecte les numéros de pièces en modifiant le fichier .bib lu par citeproc.
--
-- Fonctionnement :
--   1. Le filtre lit le(s) fichier(s) .bib listé(s) dans `meta.bibliography`.
--   2. Pour chaque clé présente dans `meta.pieces`, il injecte un champ `number`.
--   3. Il écrit un fichier .bib temporaire et redirige `meta.bibliography` vers lui.
--   4. citeproc charge ensuite le fichier temporaire, avec les numéros.

local function lire_fichier(chemin)
  local f, err = io.open(chemin, 'r')
  if not f then
    io.stderr:write("[filtre-pieces] Impossible de lire " .. chemin .. " : " .. tostring(err) .. "\n")
    return nil
  end
  local contenu = f:read('*all')
  f:close()
  return contenu
end

local function ecrire_fichier(chemin, contenu)
  local f, err = io.open(chemin, 'w')
  if not f then
    io.stderr:write("[filtre-pieces] Impossible d'écrire " .. chemin .. " : " .. tostring(err) .. "\n")
    return false
  end
  f:write(contenu)
  f:close()
  return true
end

local function injecter_number(contenu, cle, num)
  -- Cherche @misc{cle, ... } et injecte number juste après la première ligne.
  -- Gère @article, @book, @inproceedings, etc.
  local motif = '(@%w+{' .. cle:gsub('([%^%$%(%)%%%.%[%]%*%+%-%?])', '%%%1') .. ',)'
  local remplacement = '%1\n\tnumber = {' .. num .. '},'
  local nouveau, n = contenu:gsub(motif, remplacement, 1)
  if n == 0 then
    io.stderr:write("[filtre-pieces] Clé introuvable dans le .bib : " .. cle .. "\n")
  end
  return nouveau
end

function Meta(meta)
  local pieces = meta.pieces
  if not pieces then
    return meta
  end

  local bibs = meta.bibliography
  if not bibs then
    io.stderr:write("[filtre-pieces] Aucun fichier .bib déclaré dans meta.bibliography.\n")
    return meta
  end

  -- Normaliser en liste
  if bibs.t == 'MetaString' then
    bibs = pandoc.MetaList({ bibs })
  end

  local n_injectes = 0

  for i, bib in ipairs(bibs) do
    local chemin = pandoc.utils.stringify(bib)
    local contenu = lire_fichier(chemin)
    if contenu then
      for cle, num in pairs(pieces) do
        contenu = injecter_number(contenu, cle, pandoc.utils.stringify(num))
        n_injectes = n_injectes + 1
      end
      -- Écrire dans un fichier temporaire
      local temp = os.tmpname() .. '.bib'
      if ecrire_fichier(temp, contenu) then
        bibs[i] = pandoc.MetaString(temp)
      end
    end
  end

  meta.bibliography = bibs

  io.stderr:write(string.format(
    "[filtre-pieces] %d numéro(s) injecté(s) dans %d fichier(s) .bib.\n",
    n_injectes, #bibs
  ))

  return meta
end