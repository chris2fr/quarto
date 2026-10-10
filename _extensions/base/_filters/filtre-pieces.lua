-- filtre-pieces.lua
--
-- Injecte les numéros de pièces dans les entrées bibliographiques en
-- modifiant le fichier .bib lu par citeproc.
--
-- Déclaré dans `contributes.filters` de l'extension Base.

-- ---------------------------------------------------------------------------
-- Utilitaires

local function lire_fichier(chemin)
  local f, err = io.open(chemin, 'r')
  if not f then
    io.stderr:write("[filtre-pieces] Impossible de lire " .. chemin
                    .. " : " .. tostring(err) .. "\n")
    return nil
  end
  local contenu = f:read('*all')
  f:close()
  -- Normaliser les fins de ligne
  contenu = contenu:gsub('\r\n', '\n'):gsub('\r', '\n')
  return contenu
end

local function ecrire_fichier(chemin, contenu)
  local f, err = io.open(chemin, 'w')
  if not f then
    io.stderr:write("[filtre-pieces] Impossible d'écrire " .. chemin
                    .. " : " .. tostring(err) .. "\n")
    return false
  end
  f:write(contenu)
  f:close()
  return true
end

local function echapper_pattern(s)
  return (s:gsub('([%^%$%(%)%%%.%[%]%*%+%-%?])', '%%%1'))
end

-- ---------------------------------------------------------------------------
-- Filtre principal

function Meta(meta)
  local pieces = meta.pieces
  if not pieces then
    return meta
  end

  if pieces.t == 'MetaString' then
    io.stderr:write("[filtre-pieces] `pieces` est une chaîne, pas un mapping.\n")
    return meta
  end

  local bibs = meta.bibliography
  if not bibs then
    io.stderr:write("[filtre-pieces] Aucun fichier .bib déclaré.\n")
    return meta
  end

  if bibs.t == 'MetaString' then
    bibs = pandoc.MetaList({ bibs })
  end

  local n_injectes = 0
  local cles_trouvees = {}

  for i, bib in ipairs(bibs) do
    local chemin = pandoc.utils.stringify(bib)
    local contenu = lire_fichier(chemin)
    if contenu then
      local lignes = {}
      for ligne in (contenu .. '\n'):gmatch('([^\n]*)\n') do
        table.insert(lignes, ligne)
      end

      for cle, num in pairs(pieces) do
        local cle_str = pandoc.utils.stringify(cle)
        local num_str = pandoc.utils.stringify(num)
        local motif = '^@%w+{' .. echapper_pattern(cle_str) .. ',%s*$'

        for j = 1, #lignes do
          if lignes[j]:match(motif) then
            -- Supprimer tout number existant dans cette entrée
            local k = j + 1
            while k <= #lignes and not lignes[k]:match('^@') do
              if lignes[k]:match('^[ \t]*number[ \t]*=') then
                table.remove(lignes, k)
              else
                k = k + 1
              end
            end
            -- Insérer le nouveau number
            table.insert(lignes, j + 1, '\tnumber = {' .. num_str .. '},')
            cles_trouvees[cle_str] = true
            n_injectes = n_injectes + 1
            break
          end
        end
      end

      -- Fichier temporaire à côté du fichier original
      local temp = chemin .. '.' .. os.time() .. '.' .. math.random(1000, 9999) .. '.pieces.bib'
      if ecrire_fichier(temp, table.concat(lignes, '\n')) then
        bibs[i] = pandoc.MetaString(temp)
        io.stderr:write("[filtre-pieces] Temp : " .. temp .. "\n")
      end
    end
  end

  meta.bibliography = bibs

  io.stderr:write(string.format(
    "[filtre-pieces] %d numéro(s) injecté(s) dans %d fichier(s).\n",
    n_injectes, #bibs
  ))

  local orphelines = {}
  for cle, _ in pairs(pieces) do
    local cle_str = pandoc.utils.stringify(cle)
    if not cles_trouvees[cle_str] then
      table.insert(orphelines, cle_str)
    end
  end
  if #orphelines > 0 then
    io.stderr:write(string.format(
      "[filtre-pieces] %d clé(s) du mapping introuvable(s) :\n", #orphelines
    ))
    for _, c in ipairs(orphelines) do
      io.stderr:write("  - " .. c .. "\n")
    end
  end

  return meta
end