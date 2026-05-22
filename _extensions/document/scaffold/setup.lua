-- Interactive scaffold — fills in template.qmd from user input.
-- Usage: lua setup.lua [target.qmd]

local function first_qmd()
  local p = io.popen("ls *.qmd 2>/dev/null | head -1")
  if p then
    local name = p:read("*l")
    p:close()
    if name and name ~= "" then return name end
  end
end

local target = (arg and arg[1]) or first_qmd() or "template.qmd"

local f = io.open(target, "r")
if not f then
  io.stderr:write("Error: " .. target .. " not found. Run from the project root.\n")
  os.exit(1)
end
local content = f:read("*a")
f:close()

local function yaml_get(key)
  return content:match("\n" .. key .. ": ([^\n]+)") or
         content:match("^" .. key .. ": ([^\n]+)")
end

local function yaml_get_date(key)
  local date_str = yaml_get(key)
  if date_str then
    local y, m, d = date_str:match("(%d%d%d%d)-(%d%d)-(%d%d)")
    if y and m and d then
      return string.format("%04d-%02d-%02d", tonumber(y), tonumber(m), tonumber(d))
    end
  end
end

local function ask(prompt, default)
  local hint = default and (" [" .. default .. "]") or ""
  io.write(prompt .. hint .. " : ")
  io.flush()
  local input = io.read()
  return (input and input ~= "") and input or default or ""
end

local title    = ask("Titre du document    ", yaml_get("title"))
local subtitle = ask("Sous-titre           ", yaml_get("subtitle"))
local author   = ask("Auteur               ", yaml_get("author"))
local date     = ask("Date  (1789-07-14)   ", (yaml_get_date("date") or os.date("%Y-%m-%d")))
local ref      = ask("Référence            ", yaml_get("ref"))

local replacements = {
  title    = title,
  subtitle = subtitle,
  author   = author,
  date     = date,
  ref      = ref,
}

local result = {}
for line in (content .. "\n"):gmatch("([^\n]*)\n") do
  local key = line:match("^(%a+):")
  local out_line = (key and replacements[key]) and (key .. ": " .. replacements[key]) or line
  table.insert(result, out_line)
end
if result[#result] == "" then table.remove(result) end

local out = io.open(target, "w")
out:write(table.concat(result, "\n") .. "\n")
out:close()

print("\n" .. target .. " updated. Edit the document body, then:")
print("  quarto render " .. target)
