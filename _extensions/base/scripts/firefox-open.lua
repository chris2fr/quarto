-- Post-render: opens the output directory of the files just rendered in
-- Firefox. Run by Quarto via `quarto run`, so the pandoc Lua API is available.
--
-- Quarto always runs post-render scripts from the project root and lists the
-- rendered files (relative to it, one per line) in QUARTO_PROJECT_OUTPUT_FILES.
-- The folder opened is the deepest one containing all of them, e.g.
-- _output/sub/ after `quarto render sub/b.qmd`. When run by hand, the script
-- falls back to the _output/ counterpart of the current directory.

local path = pandoc.path
local system = pandoc.system

local function fail(msg)
  io.stderr:write("Error: " .. msg .. "\n")
  os.exit(1)
end

local function is_file(p)
  local f = io.open(p, "r")
  if f then f:close() return true end
  return false
end

local function is_dir(p)
  return (pcall(system.list_directory, p))
end

-- Deepest directory shared by all rendered output files, or nil
local function rendered_dir(project_dir, files)
  local common
  for file in files:gmatch("[^\r\n]+") do
    local parts = path.split(path.directory(path.join({ project_dir, file })))
    if not common then
      common = parts
    else
      local n = 0
      while n < #common and n < #parts and common[n + 1] == parts[n + 1] do
        n = n + 1
      end
      for i = #common, n + 1, -1 do common[i] = nil end
    end
  end
  if common and #common > 0 then
    return path.join(common)
  end
end

-- _output/ counterpart of the current directory, for manual runs
local function manual_dir()
  local current_dir = system.get_working_directory()
  local search_dir = current_dir
  while not is_file(path.join({ search_dir, "_quarto.yml" })) do
    local parent = path.directory(search_dir)
    if parent == search_dir then
      fail("No parent directory with _quarto.yml found")
    end
    search_dir = parent
  end
  local relative_path = path.make_relative(current_dir, search_dir)
  local target = path.join({ search_dir, "_output" })
  if relative_path ~= "." and relative_path ~= "" then
    target = path.join({ target, relative_path })
  end
  return target
end

local project_dir = os.getenv("QUARTO_PROJECT_DIR")
local target_dir
if project_dir then
  target_dir = rendered_dir(project_dir, os.getenv("QUARTO_PROJECT_OUTPUT_FILES") or "")
    or os.getenv("QUARTO_PROJECT_OUTPUT_DIR")
    or path.join({ project_dir, "_output" })
else
  target_dir = manual_dir()
end

if not is_dir(target_dir) then
  fail("Target directory does not exist: " .. target_dir)
end

-- cmd.exe on Windows (firefox is usually not on PATH, but `start` resolves
-- it), `open` on macOS, a POSIX shell with firefox on PATH elsewhere.
local cmd
if system.os == "mingw32" then
  cmd = 'start "" firefox "' .. target_dir .. '"'
else
  local quoted = "'" .. target_dir:gsub("'", "'\\''") .. "'"
  if system.os == "darwin" then
    cmd = "open -a Firefox " .. quoted
  else
    cmd = "firefox " .. quoted
  end
end
if not os.execute(cmd) then
  fail("Failed to load directory: " .. target_dir)
end
