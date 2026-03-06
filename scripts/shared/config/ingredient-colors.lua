--- Colors for ingredients (science packs)
---
--- Key is name of ItemPrototype of ingredients
---
--- @type table<string, ColorTuple>
local config_ingredient_colors = {
  ["automation-science-pack"]      = { 0.91, 0.16, 0.20 },
  ["logistic-science-pack"]        = { 0.29, 0.97, 0.31 },
  ["chemical-science-pack"]        = { 0.28, 0.93, 0.95 },
  ["production-science-pack"]      = { 0.83, 0.06, 0.92 },
  ["military-science-pack"]        = { 0.50, 0.10, 0.50 },
  ["utility-science-pack"]         = { 0.96, 0.93, 0.30 },
  ["space-science-pack"]           = { 0.80, 0.80, 0.80 },
  ["agricultural-science-pack"]    = { 0.84, 0.84, 0.15 },
  ["metallurgic-science-pack"]     = { 0.99, 0.50, 0.04 },
  ["electromagnetic-science-pack"] = { 0.89, 0.00, 0.56 },
  ["cryogenic-science-pack"]       = { 0.14, 0.18, 0.74 },
  ["promethium-science-pack"]      = { 0.10, 0.10, 0.50 },
}

return config_ingredient_colors
