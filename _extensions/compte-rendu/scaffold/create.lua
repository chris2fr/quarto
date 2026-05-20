function quarto.project.create(name)
  local author       = quarto.ask("Votre nom complet")
  local organization = quarto.ask("Nom de l'organisation", "")
  local place        = quarto.ask("Lieu de la réunion", "Paris")
  local participants = quarto.ask("Participants (liste)")
  local title        = quarto.ask("Titre / objet de la réunion")

  local tmpl = io.open(quarto.extension.path .. "/scaffold/template.qmd"):read("*a")

  tmpl = tmpl:gsub("{{author}}",       author)
  tmpl = tmpl:gsub("{{organization}}", organization)
  tmpl = tmpl:gsub("{{place}}",        place)
  tmpl = tmpl:gsub("{{participants}}", participants)
  tmpl = tmpl:gsub("{{title}}",        title)

  local out = io.open(name .. ".qmd", "w")
  out:write(tmpl)
  out:close()
end
