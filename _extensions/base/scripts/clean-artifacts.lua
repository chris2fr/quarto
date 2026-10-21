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
  -- Quarto reports outputs relative to the project root; for a source such as
  -- letters/notice.qmd, the output's stem maps back to letters/notice.qmd.
  local stem = output_file:gsub("%.[^./\\]+$", "")
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
    if format_name == "pdf" or format_name:match("%-pdf$") then
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
  if not source then return end

  local source_base = path.filename(source):gsub("%.[^./\\]+$", "")
  local output_dir = path.directory(source)
  if output_dir == "" then output_dir = "." end
  local source_pattern = "^" .. escape_pattern(source_base)
  local keep_tex = keeps_tex(source)

  for _, name in ipairs(system.list_directory(output_dir)) do
    local stem = name:gsub("%.[^./\\]+$", "")
    local belongs_to_document = stem == source_base
      or name:match(source_pattern .. "%-") ~= nil
    local p = path.join({ output_dir, name })

    if belongs_to_document then
      local ok = pcall(system.list_directory, p)
      if ok then
        if name:match("_files$") then system.remove_directory(p, true) end
      elseif is_artifact(name) and is_recent(p) then
        if not (keep_tex and name:match("%.tex$")) then os.remove(p) end
      end
    end
  end
end

local output_files = os.getenv("QUARTO_PROJECT_OUTPUT_FILES") or ""
for output_file in output_files:gmatch("[^\r\n]+") do
  cleanup_for_output(output_file)
end
