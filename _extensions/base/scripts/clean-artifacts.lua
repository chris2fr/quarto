-- Post-render cleanup: removes LaTeX/Typst intermediate files and support
-- directories that Quarto leaves next to the source .qmd files (format
-- resources such as quarto-lettre.cls are never cleaned up by Quarto itself).
-- Only top-level files are swept, so _parts/ (user-owned header/footer/body
-- overrides and an optional custom.cls) is never touched.
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

local function is_artifact(name)
  return name ~= "custom.cls"
    and (name:match("%.tex$") or name:match("^quarto%-.*%.cls$")
      or name:match("%.typ$") or name:match("%.ptc$")) ~= nil
end

-- Top-level intermediate files
for _, name in ipairs(system.list_directory(".")) do
  if not is_dir(name) and is_artifact(name) then
    os.remove(name)
  end
end

-- *_files support directories, at any depth
local function sweep(dir)
  for _, name in ipairs(system.list_directory(dir)) do
    local p = path.join({ dir, name })
    if is_dir(p) and not (dir == "." and pruned[name]) then
      if name:match("_files$") then
        system.remove_directory(p, true)
      else
        sweep(p)
      end
    end
  end
end

sweep(".")
