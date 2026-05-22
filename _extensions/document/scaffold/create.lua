function quarto.project.create(name)
  local title    = quarto.ask("Titre du document")
  local author   = quarto.ask("Auteur", "")
  local subtitle = quarto.ask("Sous-titre", "")

  local tmpl = io.open(quarto.extension.path .. "/scaffold/template.qmd"):read("*a")

  tmpl = tmpl:gsub("{{title}}",    title)
  tmpl = tmpl:gsub("{{author}}",   author)
  tmpl = tmpl:gsub("{{subtitle}}", subtitle)

  local out = io.open(name .. ".qmd", "w")
  out:write(tmpl)
  out:close()
end
