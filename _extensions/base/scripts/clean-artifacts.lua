-- Post-render cleanup: removes intermediate artifacts belonging to files in
-- QUARTO_PROJECT_OUTPUT_FILES. `_files` support directories are cleaned only
-- beside those outputs; user-owned `_parts/` directories are left untouched.
-- Run by Quarto via `quarto run`, so the pandoc Lua API is available.

local path = pandoc.path
local system = pandoc.system

-- Lua patterns (not globs): `%` escapes, `.*` is the wildcard
local keep = { "^custom%.cls$", "^_.*%.tex$", "^_.*%.cls$", "^_.*%.csl$" }

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

local function read_file(p)
  local f = io.open(p, "r")
  if not f then return nil end
  local content = f:read("*a")
  f:close()
  return content
end

local function source_for_output(output_file)
  -- Quarto reports output paths relative to the project root, but source files
  -- remain relative to the project root even when output-dir is configured.
  local project_dir = (os.getenv("QUARTO_PROJECT_DIR") or ""):gsub("\\\\", "/"):gsub("/+$", "")
  local output_dir = (os.getenv("QUARTO_PROJECT_OUTPUT_DIR") or ""):gsub("\\\\", "/"):gsub("/+$", "")
  local rendered_path = output_file:gsub("\\\\", "/")

  if project_dir ~= "" and rendered_path:sub(1, #project_dir + 1) == project_dir .. "/" then
    rendered_path = rendered_path:sub(#project_dir + 2)
  end
  if output_dir ~= "" and rendered_path:sub(1, #output_dir + 1) == output_dir .. "/" then
    rendered_path = rendered_path:sub(#output_dir + 2)
  elseif project_dir ~= "" and output_dir:sub(1, #project_dir + 1) == project_dir .. "/" then
    local relative_output_dir = output_dir:sub(#project_dir + 2)
    if rendered_path:sub(1, #relative_output_dir + 1) == relative_output_dir .. "/" then
      rendered_path = rendered_path:sub(#relative_output_dir + 2)
    end
  end

  local stem = rendered_path:gsub("%.[^./]+$", "")
  for _, extension in ipairs({ ".qmd", ".md", ".Rmd", ".rmd" }) do
    local source = stem .. extension
    if read_file(source) then return source end
  end
end

local function yaml_value(value)
  if type(value) == "boolean" then return value end
  return pandoc.utils.stringify(value):lower() == "true"
end

-- Parse front matter through Pandoc so nested format metadata is interpreted
-- consistently with Quarto.
local function keeps_tex(source)
  local content = read_file(source)
  if not content then return false end
  local ok, doc = pcall(pandoc.read, content, "markdown")
  if not ok or not doc.meta.format then return false end

  local formats = doc.meta.format
  for format_name, options in pairs(formats) do
    -- `format: pdf` (a string) yields integer keys from `pairs`; skip those.
    if type(format_name) == "string"
        and (format_name == "pdf" or format_name:match("%-pdf$")) then
      if type(options) == "table" and options["keep-tex"] ~= nil then
        return yaml_value(options["keep-tex"])
      end
    end
  end
  return false
end

local function escape_pattern(text)
  return text:gsub("([^%w])", "%%%1")
end

local function cleanup_for_output(output_file)
  local source = source_for_output(output_file)
  local document_base = source
    and path.filename(source):gsub("%.[^./\\]+$", "")
    or path.filename(output_file):gsub("%.[^./\\]+$", "")
  local output_dir = path.directory(output_file)
  if output_dir == "" then output_dir = "." end
  local keep_tex = source and keeps_tex(source) or false
  local output_pattern = "^" .. escape_pattern(document_base)

  -- Generated .tex/.ptc files and support directories live in Quarto's
  -- render working directory. Quarto reports the output file's location;
  -- check that directory first, then the source directory for execute-dir:file.
  local dirs = { output_dir }
  if source then
    local source_dir = path.directory(source)
    if source_dir == "" then source_dir = "." end
    if source_dir ~= output_dir then dirs[#dirs + 1] = source_dir end
  end

  for _, dir in ipairs(dirs) do
    local ok, names = pcall(system.list_directory, dir)
    if ok then
      for _, name in ipairs(names) do
        local stem = name:gsub("%.[^./\\]+$", "")
        local belongs_to_document = stem == document_base
          or name == document_base .. "_files"
          or name:match(output_pattern .. "%-") ~= nil
        local p = path.join({ dir, name })

        if belongs_to_document then
          local is_directory = pcall(system.list_directory, p)
          if is_directory then
            if name:match("_files$") then system.remove_directory(p, true) end
          elseif is_artifact(name) and is_recent(p) then
            if not (keep_tex and name:match("%.tex$")) then os.remove(p) end
          end
        end
      end
    end
  end
end

local output_files = os.getenv("QUARTO_PROJECT_OUTPUT_FILES") or ""
for output_file in output_files:gmatch("[^\r\n]+") do
  cleanup_for_output(output_file)
end
