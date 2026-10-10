-- Post-render cleanup: removes LaTeX/Typst intermediate files and support
-- directories that Quarto leaves next to the source .qmd files (format
-- resources such as quarto-lettre.cls are never cleaned up by Quarto itself).
-- Swept at any depth, so a .qmd rendered from a subfolder is cleaned there
-- too; _parts/ (user-owned header1/footer/body overrides and an optional
-- custom.cls) is excluded wherever it appears.
-- Run by Quarto via `quarto run`, so the pandoc Lua API is available.

local path = pandoc.path
local system = pandoc.system

local pruned = {
  ["_extensions"] = true,
  ["_output"] = true,
  [".quarto"] = true,
  [".git"] = true,
}

local function is_dir(p)
  return (pcall(system.list_directory, p))
end

-- Lua patterns (not globs): `%` escapes, `.*` is the wildcard
local keep = { "^custom%.cls$", "^_.*%.tex$", "^_.*%.cls$", "^_.*%.csl$"   }

-- Files untouched for this long are not render leftovers: keep them.
-- `times` yields a UTC ISO-8601 string, which sorts chronologically.
local MAX_AGE = 5 * 60

local function is_recent(p)
  local ok, mtime = pcall(system.times, p)
  if not ok then return true end
  return tostring(mtime) >= os.date("!%Y-%m-%dT%H:%M:%S", os.time() - MAX_AGE)
end

local function is_artifact(name)
  for _, pat in ipairs(keep) do
    if name:match(pat) then return false end
  end
  return (name:match("%.tex$") or name:match("^quarto%-.*%.cls$")
    or name:match("%.typ$") or name:match("%.ptc$")) ~= nil
end

-- Intermediate files and *_files support directories, at any depth
local function sweep(dir, top)
  for _, name in ipairs(system.list_directory(dir)) do
    local p = path.join({ dir, name })
    if is_dir(p) then
      if top and pruned[name] then
        -- skip
      elseif name == "_parts" then
        -- skip
      elseif name:match("_files$") then
        system.remove_directory(p, true)
      else
        sweep(p, false)
      end
    elseif is_artifact(name) and is_recent(p) then
      os.remove(p)
    end
  end
end

sweep(".", true)
