-- Post-render: opens the _output/ counterpart of the current directory in
-- Firefox. Run by Quarto via `quarto run`, so the pandoc Lua API is available.

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

local current_dir = system.get_working_directory()

-- Find the first parent directory containing "_quarto.yml"
local quarto_dir
local search_dir = current_dir
while true do
  if is_file(path.join({ search_dir, "_quarto.yml" })) then
    quarto_dir = search_dir
    break
  end
  local parent = path.directory(search_dir)
  if parent == search_dir then break end
  search_dir = parent
end

if not quarto_dir then
  fail("No parent directory with _quarto.yml found")
end

local relative_path = path.make_relative(current_dir, quarto_dir)
local target_dir = path.join({ quarto_dir, "_output" })
if relative_path ~= "." and relative_path ~= "" then
  target_dir = path.join({ target_dir, relative_path })
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
